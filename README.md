# Tomorrow Auth

Self-hosted, centralized authentication (Keycloak + PostgreSQL) for the Tomorrow
application suite — Web Portal, HR Web, ERP Web, Report Web, and future
applications — with a single Keycloak realm, one Single Sign-On session across
all apps, and a distinctly branded login page per application.

> Verified against **Keycloak 26.8.1** (`quay.io/keycloak/keycloak:26.8.1`), the
> latest stable image at the time this was built. All claims in this document
> about Keycloak's behavior (theme inheritance, the per-client theme
> mechanism, environment variables, health endpoints) were checked against
> this exact version — either in the Keycloak source for that tag, or by
> actually running the stack and inspecting the result. Section 16 lists
> everything that was run and what was observed.

---

## 1. Project overview and architecture

```
                          ┌───────────────────────────┐
                          │   Keycloak (realm: tomorrow) │
                          │                             │
  Web Portal ───────────▶ │  web-portal  → portal-theme │
  HR Web     ───────────▶ │  hr-web      → hr-theme     │◀── PostgreSQL
  ERP Web    ───────────▶ │  erp-web     → erp-theme    │    (persistent)
  Report Web ───────────▶ │  report-web  → report-theme │
                          └───────────────────────────┘
```

- **One realm (`tomorrow`), one user store.** Every application is an OIDC
  client in the same realm, so a user has exactly one account and one
  Keycloak SSO session, shared across apps via the standard Keycloak SSO
  cookie.
- **One login theme per client, chosen by Keycloak itself.** Keycloak's own
  theme-selection code (`DefaultThemeSelectorProvider`) already looks at a
  `login_theme` **client attribute** before falling back to the realm's
  default login theme. We use exactly that — no custom code, no rebuilt
  image. See §10 for the full explanation and the evidence that this is
  really how Keycloak behaves in this version.
- **Themes are bind-mounted**, not baked into the image, so editing or
  adding a theme is a file-system change, not a Docker build.

### What's "out of the box" vs. "custom" in this repo

| Capability | Status |
|---|---|
| Keycloak + PostgreSQL via Docker Compose | Out of the box (official images) |
| One realm, SSO across clients | Out of the box (standard Keycloak OIDC) |
| Branded login page per theme folder | Custom (4 theme folders, this repo) |
| **Different theme per client** | Out of the box — `login_theme` client attribute, a *stock* Keycloak feature that happens to have no obvious admin-console entry point until you know where to look (§10) |
| Thai + English UI | Our own strings (title, tagline, language names) are fully bilingual, **and** Keycloak's own built-in strings (button labels, validation messages, etc.) already ship in Thai inside the running image's `keycloak-themes` JAR — confirmed by extracting it directly, not just browsing GitHub source (see "Thai coverage, corrected" at the end of this document) |

---

## 2. Prerequisites

- Docker Engine with Compose v2 (`docker compose version`) — tested with
  Docker 29.4.2 / Compose v5.1.3.
- A free local port for Keycloak (default `8081`; see §5).
- No Java, Maven, or Node toolchain is needed — there is no custom image and
  no SPI extension to compile (see §10 for why).

## 3. Project structure

```
tomorrow-auth/                       (this repository)
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
├── keycloak/
│   └── themes/
│       ├── portal-theme/login/
│       │   ├── theme.properties
│       │   ├── login.ftl
│       │   ├── messages/{messages_en,messages_th}.properties
│       │   └── resources/{css/style.css, img/logo.svg}
│       ├── hr-theme/login/        (same layout)
│       ├── erp-theme/login/       (same layout)
│       └── report-theme/login/    (same layout)
└── realm/
    └── tomorrow-realm.json
```

**Deviations from the structure requested in the original spec, and why:**

- **No `extensions/` directory.** The spec anticipated a custom Keycloak SPI
  might be needed to select a theme per client, and said to add one *only if
  actually necessary*. It isn't: the stock `login_theme` client attribute
  does the job (§10), verified by actually logging into all four clients.
  Adding an unused `extensions/` folder would be exactly the "empty/misleading
  placeholder" the spec says not to create.
- **No `resources/js/` per theme.** The parent theme (`keycloak.v2`) already
  ships password show/hide and session-polling JS. A custom theme would only
  need its own JS for genuinely new interactive behavior, and none of the four
  brand identities requested one — adding an empty or copy-pasted `login.js`
  would duplicate what's already shipped and loaded.

## 4. Initial setup

```bash
git init   # if you haven't already
cp .env.example .env
```

Edit `.env` and replace **every** password placeholder — `POSTGRES_PASSWORD`,
`KC_BOOTSTRAP_ADMIN_USERNAME`/`KC_BOOTSTRAP_ADMIN_PASSWORD` — with your own
values before starting the stack. `.env` is listed in `.gitignore` and must
never be committed.

## 5. Environment configuration

All variables live in `.env` (copied from `.env.example`):

| Variable | Purpose |
|---|---|
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | Keycloak's database and credentials. PostgreSQL is **not** published to the host — only the `keycloak` container can reach it, over the internal Compose network. |
| `KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD` | Creates the first (`master` realm) admin account. Only takes effect the very first time Keycloak boots against an empty database — changing it later in `.env` has no effect until you reset the database. |
| `KEYCLOAK_PORT` | Host port Keycloak's HTTP listener is published on, **bound to `127.0.0.1` only** (default `8081` — changed from the conventional `8080` in this environment because port 8080 was already in use; use whatever is free on your machine). |
| `KC_HOSTNAME` | Hostname Keycloak reports in issued tokens/URLs for local development (default `localhost`). |

`docker-compose.yml` also sets some values directly (not meant to be
per-environment): `KC_HEALTH_ENABLED=true` (health endpoint) and three
`KC_SPI_THEME_*` variables that disable theme/template caching for
development — see §7 for what they do and why they must be changed for
production.

## 6. Starting and stopping services

```bash
docker compose up -d          # start Postgres + Keycloak (first run imports the realm)
docker compose logs -f keycloak   # watch startup / confirm "started in ...s"
docker compose down           # stop, keep all data (never add -v here)
```

`docker compose down -v` or any command that removes the `tomorrow-auth-pgdata`
volume **deletes your realm, clients and users**. Don't run it unless you
intend to start over from scratch.

## 7. Accessing the Keycloak Admin Console

1. `http://localhost:${KEYCLOAK_PORT}` (default `http://localhost:8081`).
2. Sign in to the **master** realm with `KC_BOOTSTRAP_ADMIN_USERNAME` /
   `KC_BOOTSTRAP_ADMIN_PASSWORD` from your `.env`.
3. Keycloak will prompt you to replace this temporary admin account with a
   permanent one — do this before anything resembling production use.
4. Switch realms: **Manage realms** → **tomorrow**.

## 8. Creating and configuring the realm

The realm is defined declaratively in [`realm/tomorrow-realm.json`](realm/tomorrow-realm.json)
and imported automatically the **first** time the stack starts, via Keycloak's
own `--import-realm` flag (see `docker-compose.yml`). Keycloak logs
`Realm 'tomorrow' already exists. Import skipped` on every subsequent start —
confirmed by actually restarting the container (§16) — so re-running
`docker compose up` or `restart` never overwrites realm or user data.

If you ever need to import it manually (e.g. into a separate/pre-existing
Keycloak instance): Admin Console → **Manage realms** → **Create realm** →
**Browse** → select `realm/tomorrow-realm.json` → **Create**.

Realm defaults worth knowing:
- `loginWithEmailAllowed: true`, `registrationAllowed: true`,
  `resetPasswordAllowed: true`, `rememberMe: true` — so all four themes
  exercise the "username or email", "forgot password", "remember me" and
  "register" UI paths out of the box.
- `internationalizationEnabled: true`, `supportedLocales: ["en","th"]` — see
  §16 for what is and isn't actually translated.
- `bruteForceProtected: true`, `sslRequired: "external"` (HTTPS required for
  any non-local/non-private-network client) as secure defaults.

## 9. Registering OIDC clients

Four clients ship pre-configured in the realm import, one per application:

| Client ID | Login theme | Placeholder redirect URI |
|---|---|---|
| `web-portal` | `portal-theme` | `http://localhost:3010/*` |
| `hr-web` | `hr-theme` | `http://localhost:3001/*` |
| `erp-web` | `erp-theme` | `http://localhost:3002/*` |
| `report-web` | `report-theme` | `http://localhost:3003/*` |

All four are configured as **public clients with mandatory PKCE (S256)** —
the secure default for browser-based apps, since it needs no client secret
to protect. Standard flow (Authorization Code) is enabled; direct access
grants (resource-owner password) and the implicit flow are disabled.

> `web-portal` uses `3010` rather than the `3000` you'd expect from the
> pattern above — see [`web-portal/README.md`](web-portal/README.md#why-port-3010-not-3000)
> for why, and §19 below for the actual runnable reference application.

**If your application is a confidential, server-side client instead** (i.e.
it can safely hold a secret): in the client's **Settings** tab, set
**Client authentication** to On (this turns it into a confidential client)
and add the secret to that application's own server-side configuration —
never to a value in this repo's realm JSON.

Before go-live, replace every `redirectUris`/`webOrigins` placeholder with
your real application URLs — `http://localhost:XXXX/*` is for local
development only and must never reach production.

## 10. Theme selection per client — and the extension that *wasn't* needed

**The requirement:** each OIDC client must show a different login theme.

**The naive assumption the spec warns against:** that creating four theme
folders is enough, or that a custom SPI/extension is required to route
clients to themes.

**What's actually true in Keycloak 26.8.1**, verified two ways:

1. **In the source.** Keycloak's built-in theme selector
   (`org.keycloak.theme.DefaultThemeSelectorProvider`, confirmed by reading
   the actual source file at the `26.8.1` tag) does this for the `LOGIN`
   theme type:
   ```java
   case LOGIN:
       ClientModel client = session.getContext().getClient();
       if (client != null) {
           name = client.getAttribute(LOGIN_THEME_KEY); // "login_theme"
       }
       if (name == null || name.isEmpty()) {
           name = session.getContext().getRealm().getLoginTheme();
       }
   ```
   In other words: **Keycloak already checks a `login_theme` attribute on
   the client before falling back to the realm's default login theme.**
   This has shipped in Keycloak for years; it's just not surfaced anywhere
   obvious.

2. **In the running Admin Console.** It *does* have a UI for this — it's
   just not on the "Advanced" tab, where you'd expect it. It's on
   **Clients → (client) → Settings → "Login settings" section → "Login
   theme" dropdown**, and that dropdown is correctly populated with all
   four custom themes alongside the built-in ones (screenshotted during
   verification — see §16). Each client in `realm/tomorrow-realm.json`
   sets this via its `attributes.login_theme` field, which is exactly what
   that dropdown edits.

**Conclusion: no SPI, no extensions directory, no custom Docker image.** The
realm JSON import sets the attribute once; the Admin Console lets you change
it per client afterwards. This was confirmed end-to-end by hitting each
client's `/protocol/openid-connect/auth` endpoint and inspecting which theme
rendered — all four came back correctly themed (§16).

**Security note on theme selection:** this mechanism takes its input
*only* from the client's own stored attribute (set by an admin via the
Console or the Admin REST API), never from a URL query parameter or any
other end-user-controlled input. There is no path by which a visitor can
pass `?theme=../../something` or similar to select an arbitrary theme or
path — the requirement to "not trust arbitrary URL parameters" is satisfied
by construction, not by added validation.

### Setting it via the Admin REST API / `kcadm.sh` (e.g. for an already-running realm)

```bash
# Get an admin token, then:
kcadm.sh update clients/<client-uuid> -r tomorrow -s 'attributes.login_theme=hr-theme'
```

## 11. Adding a new application

1. Decide on a theme name, e.g. `finance-theme`, and build it under
   `keycloak/themes/finance-theme/login/` (copy an existing theme as a
   starting point — see §12).
2. In the Admin Console: **Clients → Create client**, configure the
   redirect URIs/web origins for the new app, enable PKCE, then set
   **Settings → Login settings → Login theme** to `finance-theme`.
   (Equivalently, add a new client block to `realm/tomorrow-realm.json`
   with `"attributes": {"login_theme": "finance-theme", ...}` before the
   *first* import — the realm JSON is only read once, on an empty database;
   see §8.)
3. Point the new application's OIDC client configuration at
   `http://localhost:${KEYCLOAK_PORT}/realms/tomorrow` as the issuer.

## 12. Adding a new login theme

1. Create `keycloak/themes/<name>/login/theme.properties`:
   ```properties
   parent=keycloak.v2
   import=common/keycloak
   styles=${parent.styles} css/style.css
   kcBodyClass=theme-<name>
   ```
   (`${parent.styles}` *appends* your stylesheet after the inherited
   PatternFly styles instead of replacing them — this is what keeps every
   form control's accessible styling and behavior intact.)
2. Add `resources/css/style.css`, scoping every rule under
   `body.theme-<name> { ... }` (and `html.pf-v5-theme-dark body.theme-<name>`
   for the dark-mode variant — note it's `html`, not `body`, that carries the
   dark-mode class; this tripped us up during verification, see §16).
3. Optionally add `resources/img/logo.svg` and reference it from your CSS.
4. Optionally add `messages/messages_en.properties` /
   `messages/messages_th.properties` to override `loginAccountTitle` or add
   new custom keys (see the four existing themes for the pattern, including
   the `locale_en`/`locale_th` keys needed for the language-picker labels).
5. No restart needed in dev — see §13.

## 13. Development workflow

With the stack running (`docker compose up -d`), the following require **no
image rebuild and no restart**, because `docker-compose.yml` sets
`KC_SPI_THEME_CACHE_THEMES=false`, `KC_SPI_THEME_CACHE_TEMPLATES=false` and
`KC_SPI_THEME_STATIC_MAX_AGE=-1` for local development:

- Editing an existing theme's `.ftl` template — reload the login page.
- Editing an existing theme's CSS/JS/images — hard-refresh the login page.
- **Adding an entirely new theme folder** — it appears in the "Login theme"
  dropdown and `/admin/serverinfo` on the next request, with no restart.
  (Verified during this build: a throwaway theme folder was added while the
  container kept running, and showed up immediately — see §16.)

A restart is only needed for:
```bash
docker compose restart keycloak   # after changing docker-compose.yml / .env
docker compose logs -f keycloak   # tail logs while testing
```

**For production**, flip the three `KC_SPI_THEME_*` variables back to
Keycloak's defaults (i.e. remove them, or set `KC_SPI_THEME_CACHE_THEMES=true`,
`KC_SPI_THEME_CACHE_TEMPLATES=true`, and a sane positive `KC_SPI_THEME_STATIC_MAX_AGE`)
so themes are compiled and cached once instead of re-read on every request.
Deploy theme changes by updating the files at your production host's
equivalent of `./keycloak/themes` and performing a rolling restart of the
Keycloak service during a maintenance window, after testing the change in
a staging environment first.

## 14. Testing SSO

The easiest way to try this is to actually run the reference app in §19
(`web-portal/`) — `npm start` it, open `http://localhost:3010`, log in, then
jump to another client's login URL in the same browser and watch it skip
the login form. If you'd rather not run a Node app, the manual version:

1. Start the stack and open `http://localhost:${KEYCLOAK_PORT}/realms/tomorrow/protocol/openid-connect/auth?client_id=web-portal&response_type=code&redirect_uri=http://localhost:3010/&scope=openid&code_challenge=<S256-challenge>&code_challenge_method=S256`
   in a browser (a real client app would build this URL — and handle the
   PKCE challenge/verifier and the resulting code exchange — for you). You
   should see the **portal-theme** login page.
2. Create a test user (**Users → Create new user** → save → **Credentials**
   tab appears only *after* saving → **Set password**), sign in.
3. Open the equivalent URL for `hr-web` (port 3001) in the **same browser
   session**. You should be redirected straight back with an authorization
   code — **no login form shown** — because of the existing Keycloak SSO
   session. Repeat for `erp-web` / `report-web`.
4. Open `hr-web`'s URL in a **fresh/incognito session** (no cookies): you
   should see the **hr-theme** login page, confirming each client gets its
   own theme only when Keycloak actually needs to render a login screen.

This exact sequence (minus the browser — done by scripting the same HTTP
requests with `curl` and a cookie jar) was run during this build; results
are in §16.

## 15. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `port is already allocated` on `docker compose up` | Another process owns `KEYCLOAK_PORT` (default 8081) or 5432. Change `KEYCLOAK_PORT` in `.env`, or stop the other process. |
| Login page ignores your theme changes | Confirm `KC_SPI_THEME_CACHE_THEMES`/`KC_SPI_THEME_CACHE_TEMPLATES` are still `false` (dev mode) and that you're hitting the right client's login URL — each client has its *own* theme. |
| New theme folder doesn't show up in the "Login theme" dropdown | Check `theme.properties` exists and is valid (a missing `parent=` line, or a typo'd parent name, prevents Keycloak from registering the theme); check container logs for FreeMarker/theme errors. |
| `Missing parameter: code_challenge_method` on the auth endpoint | Expected — these clients require PKCE. A real OIDC client library handles this for you; for manual testing, generate a code_challenge/verifier pair. |
| One specific string is English under `ui_locales=th` | Not systemic — Keycloak's own Thai bundle already covers most stock strings (see "Thai coverage, corrected" at the end of this document). Check whether that specific key is missing from Keycloak's bundle (as `doLogIn` is) and override it in that theme's `messages_th.properties`. |
| `Realm 'tomorrow' already exists. Import skipped` in logs | Not an error — this is Keycloak confirming it did **not** overwrite your realm/user data on restart (§8). |
| Need to start completely over | `docker compose down` (data kept) then, only if you explicitly want to wipe the database, `docker volume rm tomorrow-auth-pgdata` — irreversible, confirm you mean it. |

## 16. Production deployment checklist

This repository is a **local development** setup (`start-dev`, HTTP, bind
mounts, dev theme caching disabled). Before production:

- [ ] Run `start` (not `start-dev`) with an **optimized build**
      (`kc.sh build` ahead of time, or build a custom image — at that point
      a custom image *is* the right call, unlike for local dev).
- [ ] Terminate TLS in front of Keycloak (reverse proxy / load balancer) and
      set `KC_PROXY_HEADERS` appropriately, or terminate TLS in Keycloak
      directly with `KC_HTTPS_CERTIFICATE_FILE`/`KC_HTTPS_CERTIFICATE_KEY_FILE`.
- [ ] Set `KC_HOSTNAME` to the real public hostname; do **not** use
      `KC_HOSTNAME_STRICT=false` in production.
- [ ] Re-enable theme/template caching (remove the three dev
      `KC_SPI_THEME_*` overrides — see §13).
- [ ] Replace every placeholder redirect URI / web origin with the real
      application URLs; remove any `*` wildcards.
- [ ] Generate strong, unique secrets for `POSTGRES_PASSWORD` and the
      bootstrap admin; store them in a secret manager, not `.env` on disk.
- [ ] Immediately replace the temporary bootstrap admin with a permanent
      admin user (Keycloak prompts for this), and disable interactive login
      for any svc account roles.
- [ ] Put PostgreSQL behind proper backup/retention (see below) and do not
      run it as a single container without HA if uptime matters.
- [ ] Set realistic session/token lifetimes for your security posture
      (`accessTokenLifespan`, `ssoSessionIdleTimeout`, `ssoSessionMaxLifespan`
      in the realm — currently set to development-friendly values).
- [ ] Review `bruteForceProtected`/failure-factor settings against your
      threat model.
- [ ] Run Keycloak with more than one replica behind a load balancer for
      HA, with an external Infinispan/JGroups discovery mechanism configured
      — out of scope for this repo's single-node Compose file.

## 17. Database backup and restore

```bash
# Backup (while the stack is running)
docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > backup.sql

# Restore into a fresh volume
docker compose up -d postgres
cat backup.sql | docker compose exec -T postgres psql -U "$POSTGRES_USER" "$POSTGRES_DB"
```

For production, schedule this (or a volume-level snapshot of
`tomorrow-auth-pgdata`) on a regular cadence and **test the restore path**,
not just the backup.

## 18. Reference application: Web Portal

[`web-portal/`](web-portal/) is a small, real, runnable React + Express app
that logs in against the `web-portal` client above — not just a config
example, but something you can actually `npm start` and click through. See
[`web-portal/README.md`](web-portal/README.md) for how to run it and what it
demonstrates (login → land on the protected page → logout, including
clearing the shared Keycloak SSO session). This is the piece the original
build explicitly called out as "not verified — would need a real deployed
application" (§16 below); it has since been built and the flow verified
end-to-end with a real browser session (see the appendix).

---

## What was actually run and verified (not just planned)

Everything below was executed against the real stack during this build —
not inferred from documentation:

- `docker compose config` validated, `docker compose up -d` brought up
  Postgres (healthy) and Keycloak (healthy) successfully with image
  `quay.io/keycloak/keycloak:26.8.1`.
- Startup logs confirmed `Realm 'tomorrow' imported` on first boot, then
  `Realm 'tomorrow' already exists. Import skipped` on a subsequent
  `docker compose restart keycloak` — proving restarts don't clobber data.
- A test user created via the Admin REST API persisted across that same
  restart (queried via the API before and after).
- Each client's `/protocol/openid-connect/auth` endpoint was requested
  directly; the HTML returned for `web-portal`, `hr-web`, `erp-web` and
  `report-web` carried `body` classes `theme-portal`, `theme-hr`,
  `theme-erp`, `theme-report` respectively, each with its own CSS, tagline,
  and page title — confirming per-client theme selection actually works,
  not just that it's configured.
- A full Authorization Code + PKCE login was performed against `web-portal`
  with a real test user (admin REST API → form login via `curl` with a
  cookie jar → authorization code issued). The **same session cookie** was
  then used against `hr-web`'s auth endpoint and received an immediate
  redirect with a fresh authorization code and **no login form** —
  confirming real SSO across clients with different themes, not just two
  separately-working login pages.
- `ui_locales=th` was confirmed to render our custom Thai strings
  correctly; the realm's `supportedLocales`/`internationalizationEnabled`
  were confirmed via the Admin REST API.
- A new theme directory was added to `keycloak/themes/` **while the
  container was running** and showed up in `/admin/serverinfo` without a
  restart, confirming the dev bind-mount workflow — then removed again
  (it was a throwaway smoke test, not a deliverable).
- The Admin Console was used live (via browser automation) to confirm the
  exact location of the native "Login theme" per-client control (Clients →
  *client* → Settings → "Login settings" → "Login theme"), and that its
  dropdown lists all four custom themes.
- Visual rendering was checked in a browser for light mode, OS dark-mode
  (`prefers-color-scheme: dark`), and a 375px mobile viewport. **A real bug
  was found and fixed this way**: the dark-mode CSS initially targeted
  `body.theme-X.pf-v5-theme-dark`, but Keycloak's own template actually adds
  the `pf-v5-theme-dark` class to `<html>`, not `<body>` — so the dark
  styles silently never applied. Fixed to
  `html.pf-v5-theme-dark body.theme-X` in all four stylesheets and
  re-verified visually.
- The password show/hide toggle was confirmed present (inherited from the
  parent `keycloak.v2` theme) via the accessibility tree, not assumed.
- **The `web-portal/` reference app (§18) was built and actually exercised
  end-to-end in a real browser**: visiting `/` while signed out redirected to
  the live `portal-theme` login page; signing in as a real test user redirected
  back through `/callback` (full Authorization Code + PKCE exchange, ID token
  signature verified against Keycloak's JWKS) and landed on the portal
  dashboard showing that user's real claims; clicking "Log out" performed
  RP-initiated logout and landed back on a fresh Keycloak login screen,
  confirming the shared SSO session was actually cleared, not just the local
  app session. A real port conflict was hit and fixed along the way: port
  3000 was already bound by an unrelated project's dev server on this
  machine, so `web-portal` (app + Keycloak client config, live and in the
  realm JSON) was moved to port 3010 — documented in
  `web-portal/README.md`.

**Not verified (would need real deployed applications beyond the one built):**
HR Web, ERP Web and Report Web applications consuming their respective
clients' tokens — only `web-portal` was built out as a working app. The
pattern in `web-portal/` applies directly to the other three (same flow,
different `client_id`/theme).

### Known limitations

- **Thai coverage, corrected.** An earlier version of this note claimed
  Keycloak ships no Thai translation at all, based on only the
  `keycloak/keycloak` GitHub source tree (`themes/src/main/resources/...`),
  which really does only contain `messages_en.properties`. That was the
  wrong place to look: the **running image's own
  `keycloak-themes-26.8.1.jar`** (inspected directly inside the container)
  contains a full `theme/base/login/messages/messages_th.properties` —
  Keycloak's build pipeline pulls additional languages in from elsewhere and
  bundles them into that JAR, so they never show up when browsing the
  source repo on GitHub. In practice this means most stock login strings
  (`username`, `password`, `rememberMe`, `invalidUserMessage`,
  `missingUsernameMessage`, password-policy errors, lockout/disabled-account
  messages, and more) are already in Thai out of the box, on every theme in
  this repo. The one gap found so far: `doLogIn` has no Thai value upstream
  (confirmed by grepping the extracted bundle) — each theme overrides it
  directly. If you find another stock key that's still English under
  `ui_locales=th`, that's the one real gap to patch per theme, not a
  systemic one.
- **No confidential/server-side client example.** All four clients are
  public + PKCE, the correct default for browser apps without a backend
  that can hold a secret. If an application is server-rendered and can
  protect a secret, see the note in §9 for how to switch it to
  confidential.
- **No HA/clustering configuration.** This repo is a single-node Compose
  setup appropriate for development; see §16 for what's missing for a
  production, highly-available deployment.
