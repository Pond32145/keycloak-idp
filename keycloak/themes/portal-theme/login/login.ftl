<#import "template.ftl" as layout>
<#import "social-providers.ftl" as identityProviders>
<#import "passkeys.ftl" as passkeys>

<#-- Ported from the "Login Page V08" Colorlib snippet (free for commercial  -->
<#-- use, colorlib.com/wp/template/login-page-08/), rebranded from "Sprout"  -->
<#-- to Tomorrow. The illustration/layout/colors are kept as in the source  -->
<#-- template; only copy, form wiring and a few accessibility details were  -->
<#-- changed to make this a real Keycloak login instead of a static demo.   -->
<@layout.registrationLayout displayMessage=false displayInfo=false; section>
  <#if section = "header">
    ${msg("loginAccountTitle")}
  <#elseif section = "form">
    <main class="cl-login08-demo">
      <section class="cl-login08" aria-labelledby="cl-login08-title">
        <div class="cl-login08__art" aria-hidden="true">
          <svg class="cl-login08__scene" viewBox="0 0 360 380" width="360" height="380">
            <circle cx="292" cy="62" r="30" fill="#ffd23f"/>
            <g stroke="#ffd23f" stroke-width="5" stroke-linecap="round"><path d="M292 14v-8M340 62h8M326 28l6-6M258 28l-6-6M326 96l6 6"/></g>
            <path d="M40 90c10-14 34-14 42 0 14-4 26 6 22 20H30c-8-8-2-22 10-20Z" fill="#fff"/>
            <ellipse cx="180" cy="352" rx="130" ry="14" fill="#f4a78b" opacity=".45"/>
            <path d="M180 190C150 160 110 150 92 168c24 6 48 20 88 22Z" fill="#3fa36b"/>
            <path d="M180 190c30-34 70-46 90-30-24 8-50 22-90 30Z" fill="#4fbf7f"/>
            <path d="M180 196c-6-50 8-94 30-110 6 30-6 70-30 110Z" fill="#2f8a57"/>
            <path d="M180 196c-10-40-36-70-62-76 4 30 30 58 62 76Z" fill="#57c98a"/>
            <path d="M180 196V230" stroke="#2f8a57" stroke-width="6" stroke-linecap="round"/>
            <path d="M104 226h152l-18 118a14 14 0 0 1-14 12h-88a14 14 0 0 1-14-12Z" fill="#ff7a59"/>
            <rect x="96" y="214" width="168" height="30" rx="12" fill="#ff5f3d"/>
            <g class="cl-login08__eyes-open">
              <circle cx="152" cy="282" r="9" fill="#2b1d16"/><circle cx="208" cy="282" r="9" fill="#2b1d16"/>
              <circle cx="155" cy="279" r="3" fill="#fff"/><circle cx="211" cy="279" r="3" fill="#fff"/>
            </g>
            <g class="cl-login08__eyes-shut" fill="none" stroke="#2b1d16" stroke-width="5" stroke-linecap="round">
              <path d="M142 284c6 6 14 6 20 0M198 284c6 6 14 6 20 0"/>
            </g>
            <circle cx="136" cy="304" r="9" fill="#ffb3a1"/><circle cx="224" cy="304" r="9" fill="#ffb3a1"/>
            <path d="M168 306c6 8 18 8 24 0" fill="none" stroke="#2b1d16" stroke-width="5" stroke-linecap="round"/>
            <g transform="translate(4 256)">
              <path d="M20 30h54l-6 56H26Z" fill="#6c8cff"/>
              <path d="M74 44l36-26 6 6-34 32" fill="#6c8cff"/>
              <path d="M28 30c0-16 38-16 38 0" fill="none" stroke="#4a68e0" stroke-width="6"/>
              <circle cx="118" cy="16" r="3" fill="#8fd3ff"/><circle cx="126" cy="26" r="3" fill="#8fd3ff"/>
            </g>
            <g fill="#ff5f8f"><path d="M320 200l4 10 10 4-10 4-4 10-4-10-10-4 10-4Z"/><path d="M60 180l3 7 7 3-7 3-3 7-3-7-7-3 7-3Z"/></g>
          </svg>
          <p class="cl-login08__tag">${msg("artTag")}</p>
        </div>

        <div class="cl-login08__panel">
          <div data-view>
            <div class="cl-login08__topbar">
              <p class="cl-login08__brand">
                <span class="cl-login08__logo" aria-hidden="true">
                  <svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
                    <path d="M21 3 7 12a7 7 0 0 0-3 6v8l17-11a7 7 0 0 0 3-6V3Z" fill="#4b8cff"/>
                    <path d="m27 45 14-9a7 7 0 0 0 3-6v-8L27 33a7 7 0 0 0-3 6v6Z" fill="#7a82ff"/>
                    <path d="m25 15 17 10-17 11-17-10 17-11Z" fill="#5273ef"/>
                  </svg>
                </span>
                Tomorrow
              </p>
              <#if locale?? && locale.supported?size gt 1>
                <div class="cl-login08__locale">
                  <svg viewBox="0 0 24 24" aria-hidden="true" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>
                  <select id="cl-login08-locale" aria-label="${msg("locale")}" data-locale-select>
                    <#list locale.supported as l>
                      <option value="${l.url}" <#if l.label == locale.current>selected</#if>>${l.label}</option>
                    </#list>
                  </select>
                </div>
              </#if>
            </div>
            <h1 class="cl-login08__title" id="cl-login08-title">${msg("loginGreeting")}</h1>
            <p class="cl-login08__sub">${msg("loginGreetingSub")}</p>

            <#if message?has_content && (message.type != "warning" || !isAppInitiatedAction??)>
              <p class="cl-login08__error" role="alert">${kcSanitize(message.summary)?no_esc}</p>
            </#if>

            <#if realm.password>
              <form id="kc-form-login" class="cl-login08__form" action="${url.loginAction}" method="post" onsubmit="login.disabled = true; return true;" novalidate>
                <#if !usernameHidden??>
                  <#assign usernameLabel>
                    <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                  </#assign>
                  <#assign usernamePlaceholder><#if !realm.loginWithEmailAllowed>${msg("placeholderUsername")}<#elseif !realm.registrationEmailAsUsername>${msg("placeholderUsernameOrEmail")}<#else>${msg("placeholderEmail")}</#if></#assign>
                  <div class="cl-login08__field<#if messagesPerField.existsError('username','password')> is-error</#if>">
                    <label class="cl-login08__label" for="username">${usernameLabel}</label>
                    <input class="cl-login08__input" id="username" name="username" type="text"
                      value="${(login.username!'')}"
                      placeholder="${usernamePlaceholder}"
                      autocomplete="${(enableWebAuthnConditionalUI?has_content)?then('username webauthn', 'username')}"
                      autofocus
                      aria-invalid="<#if messagesPerField.existsError('username','password')>true<#else>false</#if>" />
                    <#if messagesPerField.existsError('username','password')>
                      <p class="cl-login08__error">${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}</p>
                    </#if>
                  </div>
                </#if>

                <div class="cl-login08__field<#if messagesPerField.existsError('password')> is-error</#if>">
                  <label class="cl-login08__label" for="password">${msg("password")}</label>
                  <div class="cl-login08__pw">
                    <input class="cl-login08__input" id="password" name="password" type="password"
                      placeholder="${msg('placeholderPassword')}"
                      autocomplete="current-password"
                      aria-invalid="<#if messagesPerField.existsError('password')>true<#else>false</#if>" />
                    <button class="cl-login08__eye" type="button" aria-label="${msg('showPassword')}" aria-pressed="false" aria-controls="password"
                      data-pw-toggle data-show-label="${msg('showPassword')}" data-hide-label="${msg('hidePassword')}">
                      <svg class="cl-login08__eye-on" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>
                      <svg class="cl-login08__eye-off" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 3l18 18M10.6 5.1A10.8 10.8 0 0 1 12 5c6.4 0 10 7 10 7a17.6 17.6 0 0 1-3.2 4.1M6.6 6.6C3.9 8.3 2 12 2 12s3.6 7 10 7a9.8 9.8 0 0 0 5.4-1.6M9.9 9.9a3 3 0 0 0 4.2 4.2"/></svg>
                    </button>
                  </div>
                  <p class="cl-login08__caps" data-caps data-live-text="${msg('capsLockWarning')}" hidden>
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 4 4 12h4v4h8v-4h4Z"/><path d="M8 20h8"/></svg>
                    ${msg("capsLockWarning")}
                  </p>
                  <#if messagesPerField.existsError('password')>
                    <p class="cl-login08__error">${kcSanitize(messagesPerField.getFirstError('password'))?no_esc}</p>
                  </#if>
                </div>

                <div class="cl-login08__row">
                  <#if realm.rememberMe && !usernameHidden??>
                    <label class="cl-login08__check">
                      <input type="checkbox" id="rememberMe" name="rememberMe" <#if login.rememberMe??>checked</#if>>
                      <span>${msg("rememberMe")}</span>
                    </label>
                  <#else>
                    <span></span>
                  </#if>
                  <#if realm.resetPasswordAllowed>
                    <a class="cl-login08__link" href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a>
                  </#if>
                </div>

                <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if> />
                <button class="cl-login08__submit" name="login" id="kc-login" type="submit">${msg("doLogIn")} <span aria-hidden="true">&rarr;</span></button>
              </form>
            </#if>

            <#if realm.password && social?? && social.providers?? && social.providers?has_content>
              <@identityProviders.show social=social/>
            </#if>

            <@passkeys.conditionalUIData />

            <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
              <p class="cl-login08__foot">${msg("footerNoAccount")} <a class="cl-login08__link" href="${url.registrationUrl}">${msg("footerRegisterLink")}</a></p>
            </#if>
          </div>

          <div class="cl-login08__vh" role="status" aria-live="polite" data-live></div>
        </div>
      </section>
    </main>
    <script src="${url.resourcesPath}/js/login.js"></script>
  </#if>
</@layout.registrationLayout>
