Orange OTP VPN test — 2026-08-09

STATUS: Orange OTP ACTIVE (OTP_PROVIDER=orange, TWO_FA_DEMO_ENABLED=false)

PUBLIC URLs (for remote/VPN test device — mobile data or non-Orange DNS)
  Admin:    https://prisoners-trackbacks-lawyer-controversy.trycloudflare.com/login
  Employee: https://prisoners-trackbacks-lawyer-controversy.trycloudflare.com/app/
  APK:      /Users/macbookair/Desktop/myboss-demo-external.apk

Logins
  Admin:    admin@orange.com / admin123
  Employee: demo@orange.com + OTP (emailed via Orange, no demoOtpCode in API)

VPN requirements (host running Docker)
  1. Connect THIS Mac to Orange VPN (auth-service calls SSO + email APIs)
  2. Add Apigee apiKey to myboss-platform/.env when Orange provides it:
       ORANGE_EMAIL_API_KEY=<your-api-key>
     (also used for SSO token request)
  3. Recreate auth-service:
       cd myboss-platform && set -a && . ./.env && set +a && \
       docker compose -f docker/docker-compose.demo.yml up -d --force-recreate auth-service

Expected success logs:
  docker logs myboss-auth -f 2>&1 | grep '\[Orange OTP\]'

  Startup:
    [Orange OTP] 2FA provider=orange-email fallbackDemo=true ...
    [Orange OTP] SSO configured url=... apiKey=set|MISSING
    [Orange OTP] Email API configured url=... channel=survey_app ...

  On login:
    [Orange OTP] sendCode start ...
    [Orange OTP] SSO token request → POST ...
    [Orange OTP] SSO token acquired ...   (success)
    [Orange OTP] Email POST ...           (success)
    [Orange OTP] Email dispatched ...     (success)

  On failure:
    [Orange OTP] SSO failed HTTP 401 ...
    [Orange OTP] VPN fallback active — use demoOtpCode ...

If SSO fails: check VPN + ORANGE_EMAIL_API_KEY
If email fails: check VPN + channel apiKey from Orange support

Keep Mac awake + cloudflared running (screen: myboss-cf).
