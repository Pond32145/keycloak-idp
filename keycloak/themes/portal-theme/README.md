# Tomorrow Identity Platform — Keycloak Login Theme

An original split-screen login theme for Keycloak 26.x, branded as Tomorrow Identity Platform.

## Install
1. Copy the `portal-theme` directory into Keycloak's themes directory:
   `/opt/keycloak/themes/portal-theme`
2. The resulting structure should be:
   `themes/portal-theme/login/theme.properties`
3. Select **portal-theme** as the Login Theme in the `tomorrow` realm:
   Realm settings → Themes → Login theme → `portal-theme`
4. For Docker Compose, mount the local directory into the container, for example:
   `./themes/portal-theme:/opt/keycloak/themes/portal-theme`
5. If theme caching is enabled, restart Keycloak after changing theme files. During development, Keycloak can be started with `--spi-theme--static-max-age=-1 --spi-theme--cache-themes=false --spi-theme--cache-templates=false`.

## Notes
- The form posts to Keycloak's own `url.loginAction`; it does not authenticate in JavaScript.
- Username/password, remember-me, reset-password, registration, social-provider rendering, and passkey conditional UI are retained where enabled by the realm.
- Social login provider layout depends on the markup emitted by the Keycloak version and provider configuration; review it in the browser after installation.
- Verify the theme against your exact Keycloak version before production use.


This build includes layout overrides for Keycloak's outer registration layout and hides the duplicate built-in locale selector.
