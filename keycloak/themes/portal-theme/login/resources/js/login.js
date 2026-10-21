/*!
 * Tomorrow Portal login — adapted from Colorlib's "Login Page V08" snippet.
 * Kept: password show/hide (with the mascot "shy" eyes animation) and the
 * Caps Lock tip — both purely client-side niceties.
 * Dropped from the source snippet: its own field-validation-on-blur system
 * and the fake "submit -> success panel" flow. Those simulated a backend
 * that doesn't exist in the demo; here the <form> really posts to Keycloak
 * (url.loginAction in login.ftl), and Keycloak's own server-rendered
 * messagesPerField errors are what's shown on a bad login, not client JS.
 */
(() => {
  "use strict";

  const root = document.querySelector(".cl-login08");
  if (!root) return;

  const pwInput = document.getElementById("password");
  const toggle = root.querySelector("[data-pw-toggle]");
  const caps = root.querySelector("[data-caps]");
  const live = root.querySelector("[data-live]");
  if (!pwInput || !toggle) return;

  const shy = () =>
    root.classList.toggle(
      "is-shy",
      document.activeElement === pwInput && pwInput.type === "password"
    );
  pwInput.addEventListener("focus", shy);
  pwInput.addEventListener("blur", () => {
    root.classList.remove("is-shy");
    if (caps) caps.hidden = true;
  });

  toggle.addEventListener("click", () => {
    const show = pwInput.type === "password";
    pwInput.type = show ? "text" : "password";
    toggle.setAttribute("aria-pressed", String(show));
    toggle.setAttribute(
      "aria-label",
      show ? toggle.dataset.hideLabel : toggle.dataset.showLabel
    );
    shy();
  });

  if (caps) {
    let capsOn = false;
    const capsCheck = (e) => {
      if (typeof e.getModifierState !== "function") return;
      const on = e.getModifierState("CapsLock");
      caps.hidden = !on;
      if (on !== capsOn) {
        capsOn = on;
        if (live) live.textContent = on ? caps.dataset.liveText || "" : "";
      }
    };
    pwInput.addEventListener("keydown", capsCheck);
    pwInput.addEventListener("keyup", capsCheck);
  }

  const localeSelect = root.querySelector("[data-locale-select]");
  if (localeSelect) {
    localeSelect.addEventListener("change", () => {
      if (localeSelect.value) window.location.href = localeSelect.value;
    });
  }
})();
