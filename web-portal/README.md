# Tomorrow Web Portal (reference application)

A real, runnable example of an application that authenticates against
**Tomorrow Auth** (see the [main README](../README.md)) using the `web-portal`
OIDC client that's already pre-configured in `realm/tomorrow-realm.json`.

It exists to prove the whole chain actually works end-to-end — not just that
Keycloak is configured correctly, but that a real app can log a user in, land
them on a protected page, and log them out (including the shared SSO
session) — using nothing but standard OIDC.

## Architecture

- **`server/`** — Express backend. Owns the entire OIDC Authorization Code +
  PKCE flow (`/login`, `/callback`, `/logout`), keeps the signed-in user in a
  server-side session (cookie holds only a session ID, never the tokens
  themselves... except the ID token, kept server-side for RP-initiated
  logout — never sent to the browser), and serves the built React app.
  The browser never sees an access/ID/refresh token directly.
- **`client/`** — React (Vite) frontend. A single page that calls `/api/me`
  for the signed-in user's profile and renders a "Log out" link. No OIDC
  logic lives here at all — that's the backend's job.

This is the standard "confidential-style backend handles auth" pattern, even
though `web-portal` is registered as a *public* Keycloak client (no secret):
PKCE is what replaces the client secret here, and it's the Express process,
not the browser, that holds the authorization code verifier and performs the
token exchange.

## Running it

Prerequisite: the Tomorrow Auth stack must already be running
(`docker compose up -d` in the repo root) and reachable at
`http://localhost:8081`.

```bash
# one-time setup
cd web-portal/server && npm install
cd ../client && npm install && npm run build

# run
cd ../server
npm start
```

Open **http://localhost:3010** — you'll be redirected straight to Keycloak's
`portal-theme` login page if you don't have a session yet, or straight to the
dashboard if you do (SSO).

Create a test user first if you haven't: Admin Console (`http://localhost:8081`)
→ realm **tomorrow** → **Users** → **Create new user** → save → **Credentials**
tab → **Set password** (turn the "Temporary" toggle off).

### Why port 3010, not 3000?

`realm/tomorrow-realm.json`'s original placeholder used `3000`, matching the
"Web Portal" row in the main README's client table. While building this app
on this particular machine, port `3000` turned out to already be in use by
an unrelated project's Vite dev server
(`play-code/logto-loginnn/custom-login`) — nothing to do with this repo, and
not something to shut down just to free the port. Both the Keycloak client
(`web-portal`'s redirect URIs/web origins/post-logout-redirect-uri) and this
app were moved to **3010** instead. If port 3000 is free on your machine, you
can switch back by editing `server/.env` (`PORT`, `APP_BASE_URL`) and
updating the `web-portal` client's redirect URIs the same way (Admin Console
→ Clients → web-portal → Settings, or edit `realm/tomorrow-realm.json` before
the *first* import).

## One origin, not two — `client/`'s dev server is UI-only

There is **one correct entry point for this app: `http://localhost:3010`**
(Express). `cd client && npm run dev` (Vite, typically `:5173`+) is useful
for iterating on markup/CSS with hot reload, but it does **not** replace
Express — it serves the React bundle directly, bypassing the server-side
check that gates `/` on having a session. If you open the Vite dev server
directly, you'll never see the automatic redirect-to-Keycloak behavior,
because that logic lives in `server.js`, not in the React app.

This is intentional, not a shortcut taken for convenience: OIDC requires a
client's `redirect_uri` to be a **fixed value pre-registered with the
identity provider** (that's the whole point — it's what stops an attacker
from redirecting a stolen authorization code somewhere else). `server.js`
hardcodes `redirect_uri` to `${APP_BASE_URL}/callback`, i.e. always
`http://localhost:3010/callback`, matching exactly what's registered on the
`web-portal` client in Keycloak. Making that dynamic per-origin so a second
dev port could complete login too would mean accepting a list of
"trusted" origins and picking one per request — more attack surface for a
convenience this app doesn't need, since the backend already serves the
frontend itself at `:3010` in every real run.

**In short:** always log in through `:3010`. Use `npm run dev` only to look
at UI changes without caring about the auth flow, then verify the real
thing at `:3010` (rebuild with `npm run build` first — `:3010` serves the
built `dist/`, not Vite's dev output).

## What to try

1. **Login → landing page.** Visiting `/` while signed out goes straight to
   Keycloak; after entering valid credentials you land back on the portal's
   dashboard automatically (via `/callback` → session set → redirect to `/`).
2. **SSO.** After logging in here, open one of the other clients' login URLs
   (see the main README's §14, swap in `hr-web`/`erp-web`/`report-web`) in
   the same browser — no login form appears, because the Keycloak SSO
   session is shared.
3. **Logout.** Click "Log out". This clears the local Express session *and*
   performs RP-initiated logout against Keycloak (passing `id_token_hint`),
   so the shared SSO session is gone too — reload any client's login URL
   afterwards and you'll be asked to authenticate again.

## Known simplifications (this is a reference app, not production code)

- **No token refresh.** The access/ID token issued at login is used for the
  lifetime of the Express session; there's no silent refresh using the
  refresh token. Fine for a demo session; a real app would refresh before
  `accessTokenLifespan` (300s in the realm config) expires, or re-trigger
  `/login`.
- **In-memory session store.** `express-session`'s default `MemoryStore` is
  used, which is explicitly not for production (it leaks memory and doesn't
  survive a restart or scale past one process). Swap in a real store
  (Redis, Postgres, etc.) before deploying anywhere real.
- **`npm audit` flags a moderate vulnerability in `vite`'s bundled `esbuild`**
  (dev-server-only CORS issue, [GHSA-67mh-4wv8-2f99](https://github.com/advisories/GHSA-67mh-4wv8-2f99)).
  It only affects `vite dev`, which this app's normal run path doesn't use
  (`npm start` serves the pre-built `dist/` via Express) — but avoid running
  `vite dev` exposed beyond localhost, and upgrade when convenient.
