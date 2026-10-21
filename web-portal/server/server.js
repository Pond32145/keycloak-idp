import "dotenv/config";
import express from "express";
import session from "express-session";
import crypto from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRemoteJWKSet, jwtVerify } from "jose";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// --- Configuration (override via environment variables / .env) -----------
const PORT = process.env.PORT || 3010;
const APP_BASE_URL = process.env.APP_BASE_URL || `http://localhost:${PORT}`;
const KEYCLOAK_ISSUER =
  process.env.KEYCLOAK_ISSUER || "http://localhost:8081/realms/tomorrow";
const CLIENT_ID = process.env.CLIENT_ID || "web-portal";
const SESSION_SECRET = process.env.SESSION_SECRET || "dev-only-change-me";

// The Vite dev server (client/vite.config.js, strictPort: true) is treated
// as a second legitimate front door — not just APP_BASE_URL — so that
// `npm run dev` can complete a real login and land back on itself, same as
// a user would expect from any "sign in with X" flow. Both origins must
// also be registered on the `web-portal` Keycloak client's redirect URIs /
// web origins / post-logout-redirect-uris (realm/tomorrow-realm.json).
// This is a short, explicit allow-list, not a wildcard: the redirect_uri
// OAuth sends the authorization code to must always be one of a few known,
// pre-registered values, never whatever a request claims it is.
const DEV_ORIGIN = process.env.DEV_ORIGIN || "http://localhost:5190";
const ALLOWED_ORIGINS = new Set([APP_BASE_URL, DEV_ORIGIN]);

function resolveOrigin(req) {
  const candidate = req.headers.origin || req.headers.referer;
  if (candidate) {
    try {
      const origin = new URL(candidate).origin;
      if (ALLOWED_ORIGINS.has(origin)) return origin;
    } catch {
      // Malformed header — fall through to the default below.
    }
  }
  return APP_BASE_URL;
}

if (SESSION_SECRET === "dev-only-change-me") {
  console.warn(
    "[web-portal] Using the default SESSION_SECRET — fine for local dev, " +
      "but set a real SESSION_SECRET env var before deploying anywhere else."
  );
}

// --- OIDC discovery ---------------------------------------------------
// web-portal is registered in Keycloak as a PUBLIC client with mandatory
// PKCE (see realm/tomorrow-realm.json), so no client secret is needed here:
// the code_verifier/code_challenge pair is what proves this server is the
// same party that started the login.
// Keycloak in dev mode re-runs its Quarkus "build" step on every start, which
// alone can take 30-90+ seconds before it even begins accepting connections
// (observed firsthand: ~75s on a first boot, 20-30s on a plain restart) —
// on top of however long `docker compose up` takes to get the container
// running at all. The original 20 retries x 1.5s (30s total) was nowhere
// near enough and failed with a misleading error while Keycloak was still
// mid-startup. These defaults give it up to ~4 minutes before giving up for
// real; override via DISCOVERY_RETRIES / DISCOVERY_DELAY_MS if your machine
// needs even longer.
const DISCOVERY_RETRIES = Number(process.env.DISCOVERY_RETRIES) || 80;
const DISCOVERY_DELAY_MS = Number(process.env.DISCOVERY_DELAY_MS) || 3000;

async function discover(issuer, retries = DISCOVERY_RETRIES, delayMs = DISCOVERY_DELAY_MS) {
  const url = `${issuer}/.well-known/openid-configuration`;
  const totalSeconds = Math.round((retries * delayMs) / 1000);
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (err) {
      if (attempt === retries) {
        throw new Error(
          `Could not reach Keycloak discovery document at ${url} after ${retries} attempts (~${totalSeconds}s): ${err.message}\n` +
            "Is the tomorrow-auth stack running? (docker compose up -d in the keycloak project, then wait for " +
            "`docker compose ps` to show keycloak as \"healthy\" — it takes a while, especially on first boot)."
        );
      }
      if (attempt === 1 || attempt % 5 === 0) {
        console.log(
          `[web-portal] Waiting for Keycloak (${url}) — attempt ${attempt}/${retries}, giving it up to ~${totalSeconds}s total...`
        );
      }
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
}

console.log(`[web-portal] Discovering OIDC config from ${KEYCLOAK_ISSUER} ...`);
const oidc = await discover(KEYCLOAK_ISSUER);
const jwks = createRemoteJWKSet(new URL(oidc.jwks_uri));
console.log("[web-portal] OIDC discovery complete.");

// --- PKCE helpers -------------------------------------------------------
function base64url(buffer) {
  return buffer
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function createPkcePair() {
  const codeVerifier = base64url(crypto.randomBytes(32));
  const codeChallenge = base64url(
    crypto.createHash("sha256").update(codeVerifier).digest()
  );
  return { codeVerifier, codeChallenge };
}

// --- App ------------------------------------------------------------
const app = express();
app.set("trust proxy", 1);

app.use(
  session({
    name: "webportal.sid",
    secret: SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: "lax",
      // `secure` is left off for local http:// development. Set it (and run
      // behind TLS) before deploying anywhere else — see the main README's
      // production checklist.
    },
  })
);

function requireAuth(req, res, next) {
  if (!req.session.user) return res.redirect("/login");
  next();
}

// GET /login — start the Authorization Code + PKCE flow.
app.get("/login", (req, res) => {
  const { codeVerifier, codeChallenge } = createPkcePair();
  const state = base64url(crypto.randomBytes(16));
  const nonce = base64url(crypto.randomBytes(16));

  const redirectUri = `${resolveOrigin(req)}/callback`;
  req.session.pending = { codeVerifier, state, nonce, redirectUri };

  const params = new URLSearchParams({
    client_id: CLIENT_ID,
    response_type: "code",
    scope: "openid profile email",
    redirect_uri: redirectUri,
    state,
    nonce,
    code_challenge: codeChallenge,
    code_challenge_method: "S256",
  });

  res.redirect(`${oidc.authorization_endpoint}?${params.toString()}`);
});

// GET /callback — Keycloak redirects here with ?code&state after login.
app.get("/callback", async (req, res) => {
  const { code, state, error, error_description: errorDescription } = req.query;
  const pending = req.session.pending;
  req.session.pending = undefined;

  if (error) {
    return res
      .status(400)
      .send(renderError(`Keycloak returned an error: ${error} — ${errorDescription || ""}`));
  }
  if (!pending || !state || state !== pending.state) {
    return res
      .status(400)
      .send(renderError("Login state mismatch or expired session. Please try logging in again."));
  }

  try {
    // Must be byte-for-byte the same redirect_uri sent in the original
    // /login authorization request — Keycloak (like any OAuth server)
    // rejects a mismatch. That's why it was saved on `pending` rather than
    // recomputed here: resolveOrigin(req) on *this* request would look at
    // the wrong Origin/Referer (Keycloak's, not the browser's original
    // page).
    const tokenRes = await fetch(oidc.token_endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code: String(code),
        redirect_uri: pending.redirectUri,
        client_id: CLIENT_ID,
        code_verifier: pending.codeVerifier,
      }),
    });

    if (!tokenRes.ok) {
      const body = await tokenRes.text();
      throw new Error(`Token endpoint returned ${tokenRes.status}: ${body}`);
    }

    const tokens = await tokenRes.json();

    const { payload: idTokenClaims } = await jwtVerify(tokens.id_token, jwks, {
      issuer: oidc.issuer,
      audience: CLIENT_ID,
    });

    if (idTokenClaims.nonce !== pending.nonce) {
      throw new Error("ID token nonce mismatch");
    }

    req.session.user = {
      sub: idTokenClaims.sub,
      username: idTokenClaims.preferred_username,
      email: idTokenClaims.email,
      name: idTokenClaims.name,
    };
    req.session.idToken = tokens.id_token;

    res.redirect("/");
  } catch (err) {
    console.error("[web-portal] Callback failed:", err);
    res.status(500).send(renderError("Login failed while exchanging the authorization code. See server logs for details."));
  }
});

// GET /logout — clear our session, then RP-initiated logout at Keycloak so
// the shared SSO session (and therefore other tomorrow-auth apps) is really
// signed out too, not just this app.
app.get("/logout", (req, res) => {
  const idToken = req.session.idToken;
  const origin = resolveOrigin(req);
  req.session.destroy(() => {
    const params = new URLSearchParams({
      client_id: CLIENT_ID,
      post_logout_redirect_uri: origin,
    });
    if (idToken) params.set("id_token_hint", idToken);
    res.redirect(`${oidc.end_session_endpoint}?${params.toString()}`);
  });
});

app.get("/api/me", requireAuth, (req, res) => {
  res.json(req.session.user);
});

// --- Serve the React build --------------------------------------------
const clientDist = path.join(__dirname, "..", "client", "dist");

// The home page is the only route gated here: unauthenticated visitors are
// bounced to /login before any app code is served. Static assets (JS/CSS)
// are not sensitive and are served to anyone, same as any public bundle.
app.get("/", requireAuth, (req, res, next) => next());
app.use(express.static(clientDist));

function renderError(message) {
  return `<!doctype html><html><body style="font-family: system-ui; padding: 2rem;">
    <h1>Something went wrong</h1>
    <p>${message}</p>
    <p><a href="/login">Try logging in again</a></p>
  </body></html>`;
}

app.listen(PORT, () => {
  console.log(`[web-portal] Listening on ${APP_BASE_URL}`);
  console.log(`[web-portal] Keycloak issuer: ${KEYCLOAK_ISSUER}`);
});
