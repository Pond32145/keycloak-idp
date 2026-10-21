import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// `npm run build` outputs to ./dist, which server.js serves directly — no
// dev server is used in the normal run path. `npm run dev` here still works
// for iterating on the UI with hot reload, and can now also complete a real
// login (server.js recognizes this exact origin as a second valid redirect
// target — see ALLOWED_ORIGINS there).
//
// Port 5190 (not Vite's default 5173) and `strictPort: true` are both
// deliberate: Vite's default of silently trying 5174, 5175, ... when a port
// is busy is exactly what broke login the first time this was built on this
// machine — the client has *other*, unrelated projects' dev servers
// permanently parked on 5173-5175. A fixed, less common port avoids that
// collision; `strictPort` turns a future one into a loud failure instead of
// a silent mismatch with the Keycloak client's registered redirect URIs
// (and the allow-list in server.js) ever again.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5190,
    strictPort: true,
    proxy: {
      "/api": "http://localhost:3010",
      "/login": "http://localhost:3010",
      "/logout": "http://localhost:3010",
      "/callback": "http://localhost:3010",
    },
  },
});
