import { useEffect, useState } from "react";

export default function App() {
  const [user, setUser] = useState(null);
  const [status, setStatus] = useState("loading"); // loading | ready | error

  useEffect(() => {
    fetch("/api/me", { credentials: "include" })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data) => {
        setUser(data);
        setStatus("ready");
      })
      .catch(() => {
        setStatus("error");
        // The real gate lives server-side (Express refuses to serve "/"
        // without a session), so getting here only happens in edge cases —
        // e.g. this page loaded via the Vite *dev* server (`npm run dev`,
        // which serves React directly and never passes through Express) or
        // a session that expired after the page was already open. Either
        // way, the UX contract is "no login button to click", so redirect
        // automatically instead of showing a link.
        window.location.href = "/login";
      });
  }, []);

  if (status === "loading" || status === "error") {
    return <div className="centered">Redirecting to sign-in…</div>;
  }

  const initials = (user.name || user.username || "?")
    .split(" ")
    .map((p) => p[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <div className="page">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true" />
          Tomorrow Portal
        </div>
        <a className="btn-logout" href="/logout">
          Log out
        </a>
      </header>

      <main className="content">
        <div className="card">
          <div className="avatar">{initials}</div>
          <h1>Welcome back, {user.name || user.username}</h1>
          <p className="subtitle">
            You're signed in via Tomorrow Auth (Keycloak). This same session
            works across HR, ERP and Report too — no need to log in again.
          </p>

          <dl className="profile">
            <dt>Username</dt>
            <dd>{user.username}</dd>
            <dt>Email</dt>
            <dd>{user.email || "—"}</dd>
            <dt>Subject (sub)</dt>
            <dd className="mono">{user.sub}</dd>
          </dl>
        </div>
      </main>
    </div>
  );
}
