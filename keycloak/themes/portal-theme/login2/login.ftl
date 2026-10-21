<#import "template.ftl" as layout>
<#import "social-providers.ftl" as identityProviders>
<#import "passkeys.ftl" as passkeys>

<@layout.registrationLayout displayMessage=false displayInfo=false; section>
  <#if section = "header">
    ${msg("loginAccountTitle")}
  <#elseif section = "form">
    <main class="tm-page">
      <section class="tm-showcase" aria-label="Tomorrow Identity Platform">
        <div class="tm-orbit tm-orbit-one"></div>
        <div class="tm-orbit tm-orbit-two"></div>
        <div class="tm-brand">
          <span class="tm-logo" aria-hidden="true">
            <svg viewBox="0 0 48 48" role="img" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="tmLogoA" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#79c4ff"/>
                  <stop offset="1" stop-color="#4770ff"/>
                </linearGradient>
                <linearGradient id="tmLogoB" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="#a3b5ff"/>
                  <stop offset="1" stop-color="#6575f5"/>
                </linearGradient>
              </defs>
              <path d="M21 3 7 12a7 7 0 0 0-3 6v8l17-11a7 7 0 0 0 3-6V3Z" fill="url(#tmLogoA)"/>
              <path d="m27 45 14-9a7 7 0 0 0 3-6v-8L27 33a7 7 0 0 0-3 6v6Z" fill="url(#tmLogoB)"/>
              <path d="m25 15 17 10-17 11-17-10 17-11Z" fill="#6f91ff" opacity=".96"/>
            </svg>
          </span>
          <span class="tm-brand-copy">
            <strong>Tomorrow</strong>
            <small>Identity Platform</small>
          </span>
        </div>

        <div class="tm-hero-copy">
          <span class="tm-eyebrow"><span></span> YOUR DIGITAL WORKSPACE</span>
          <h1>Tomorrow is <em>Today.</em></h1>
          <p class="tm-hero-subtitle">One account. Every possibility.<br/>Your workspace starts here.</p>

          <div class="tm-benefits">
            <div class="tm-benefit">
              <span class="tm-benefit-icon" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="M12 2 4 5v6c0 5.1 3.4 9.1 8 11 4.6-1.9 8-5.9 8-11V5l-8-3Zm-1 14-4-4 1.4-1.4L11 13.2l4.6-4.6L17 10l-6 6Z"/></svg>
              </span>
              <span><strong>Secure by design</strong><small>Your access, protected.</small></span>
            </div>
            <div class="tm-benefit">
              <span class="tm-benefit-icon" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="M13 2 3 14h7l-1 8 12-14h-8l1-6Z"/></svg>
              </span>
              <span><strong>One seamless experience</strong><small>Move between tools with ease.</small></span>
            </div>
            <div class="tm-benefit">
              <span class="tm-benefit-icon" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm6.9 9h-3a15.6 15.6 0 0 0-1.3-5.2A8 8 0 0 1 18.9 11ZM12 4.1c.9 1.2 1.7 3.6 1.9 6.9h-3.8c.2-3.3 1-5.7 1.9-6.9ZM9.4 5.8A15.6 15.6 0 0 0 8.1 11h-3a8 8 0 0 1 4.3-5.2ZM5.1 13h3a15.6 15.6 0 0 0 1.3 5.2A8 8 0 0 1 5.1 13Zm6.9 6.9c-.9-1.2-1.7-3.6-1.9-6.9h3.8c-.2 3.3-1 5.7-1.9 6.9Zm2.6-1.7a15.6 15.6 0 0 0 1.3-5.2h3a8 8 0 0 1-4.3 5.2Z"/></svg>
              </span>
              <span><strong>Connected ecosystem</strong><small>Everything in one place.</small></span>
            </div>
          </div>
        </div>

        <div class="tm-hero-footer">
          <span class="tm-footer-mark"></span>
          <span>One identity. More possibilities.</span>
          <span class="tm-footer-right">TOMORROW · IDENTITY</span>
        </div>
      </section>

      <section class="tm-login-side">
        <div class="tm-topbar">
          <span class="tm-secure-note"><span class="tm-secure-dot"></span> Secure sign in</span>
          <div class="tm-locale">
            <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>
            <#if locale?? && locale.supported?size gt 1>
              <div class="tm-locale-select">
                <select id="kc-locale" aria-label="${msg("locale")}">
                  <#list locale.supported as l>
                    <option value="${l.url}" <#if l.label == locale.current>selected</#if>>${l.label}</option>
                  </#list>
                </select>
                <span aria-hidden="true">⌄</span>
              </div>
            <#else>
              <span>${(locale.current)!'English'}</span>
            </#if>
          </div>
        </div>

        <div class="tm-card-wrap">
          <div class="tm-card">
            <div class="tm-card-brand">
              <span class="tm-card-logo" aria-hidden="true">
                <svg viewBox="0 0 48 48"><path d="M21 3 7 12a7 7 0 0 0-3 6v8l17-11a7 7 0 0 0 3-6V3Z" fill="#4b8cff"/><path d="m27 45 14-9a7 7 0 0 0 3-6v-8L27 33a7 7 0 0 0-3 6v6Z" fill="#7a82ff"/><path d="m25 15 17 10-17 11-17-10 17-11Z" fill="#5273ef"/></svg>
              </span>
              <span><strong>Tomorrow</strong><small>Identity Platform</small></span>
            </div>

            <div class="tm-heading">
              <h2>${msg("loginWelcomeTitle")}</h2>
              <p>${msg("loginWelcomeSubtitle")}</p>
            </div>

            <#if message?has_content && (message.type != "warning" || !isAppInitiatedAction??)>
              <div class="tm-alert tm-alert-${message.type}" role="alert">
                <span class="tm-alert-icon" aria-hidden="true">!</span>
                <span>${kcSanitize(message.summary)?no_esc}</span>
              </div>
            </#if>

            <#if realm.password>
              <form id="kc-form-login" class="tm-form" action="${url.loginAction}" method="post" onsubmit="this.querySelector('[type=submit]').disabled=true; return true;">
                <#if !usernameHidden??>
                  <#assign usernameLabel>
                    <#if !realm.loginWithEmailAllowed>
                      ${msg("username")}
                    <#elseif !realm.registrationEmailAsUsername>
                      ${msg("usernameOrEmail")}
                    <#else>
                      ${msg("email")}
                    </#if>
                  </#assign>
                  <div class="tm-field">
                    <label for="username">${usernameLabel}</label>
                    <div class="tm-input-wrap">
                      <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/></svg>
                      <input id="username" name="username" type="text" value="${(login.username!'')}" autocomplete="${(enableWebAuthnConditionalUI?has_content)?then('username webauthn', 'username')}" autofocus tabindex="1" aria-invalid="<#if messagesPerField.existsError('username','password')>true<#else>false</#if>" />
                    </div>
                    <#if messagesPerField.existsError('username','password')>
                      <span class="tm-field-error">${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}</span>
                    </#if>
                  </div>
                </#if>

                <div class="tm-field">
                  <div class="tm-label-row">
                    <label for="password">${msg("password")}</label>
                    <#if realm.resetPasswordAllowed>
                      <a class="tm-forgot" href="${url.loginResetCredentialsUrl}" tabindex="5">${msg("doForgotPassword")}</a>
                    </#if>
                  </div>
                  <div class="tm-input-wrap">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>
                    <input id="password" name="password" type="password" autocomplete="current-password" tabindex="2" aria-invalid="<#if messagesPerField.existsError('password')>true<#else>false</#if>" />
                    <button class="tm-password-toggle" type="button" aria-label="${msg("showPassword")}" aria-controls="password" onclick="const p=document.getElementById('password');const shown=p.type==='password';p.type=shown?'text':'password';this.setAttribute('aria-label',shown?'${msg("hidePassword")}':'${msg("showPassword")}');this.querySelector('svg').style.opacity=shown?'1':'.7';">
                      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                  </div>
                  <#if messagesPerField.existsError('password')>
                    <span class="tm-field-error">${kcSanitize(messagesPerField.getFirstError('password'))?no_esc}</span>
                  </#if>
                </div>

                <div class="tm-options">
                  <#if realm.rememberMe && !usernameHidden??>
                    <label class="tm-remember" for="rememberMe">
                      <input id="rememberMe" name="rememberMe" type="checkbox" tabindex="3" <#if login.rememberMe??>checked</#if> />
                      <span>${msg("rememberMe")}</span>
                    </label>
                  <#else>
                    <span></span>
                  </#if>
                  <span class="tm-session-note"><span class="tm-session-dot"></span> ${msg("loginSecureSession")}</span>
                </div>

                <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if> />
                <button id="kc-login" class="tm-submit" name="login" type="submit" tabindex="4">
                  <span>${msg("doLogIn")}</span>
                  <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14M13 5l7 7-7 7"/></svg>
                </button>
              </form>
            </#if>

            <#if realm.password && social?? && social.providers?? && social.providers?has_content>
              <div class="tm-divider"><span></span><small>${msg("loginOrContinueWith")}</small><span></span></div>
              <@identityProviders.show social=social/>
            </#if>

            <@passkeys.conditionalUIData />

            <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
              <div class="tm-register">
                <span>${msg("noAccount")}</span>
                <a href="${url.registrationUrl}" tabindex="6">${msg("doRegister")}</a>
              </div>
            </#if>
          </div>
          <p class="tm-legal">${msg("loginFooterText")}</p>
        </div>
      </section>
    </main>
    <script>
      (function () {
        var localeSelect = document.getElementById('kc-locale');
        if (localeSelect) localeSelect.addEventListener('change', function () {
          if (this.value) window.location.href = this.value;
        });
      })();
    </script>
  </#if>
</@layout.registrationLayout>
