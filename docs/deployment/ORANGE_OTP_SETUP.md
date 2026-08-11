# Orange OTP — email verification setup

**Audience:** Backend developers, DevOps  
**Purpose:** Send sign-in OTP codes via Orange SSO + Maxit email API (instead of demo console OTP)

The auth-service calls Orange **internally** — mobile and admin never contact these APIs directly.

---

## Flow

```
POST /auth/sign-in { email }
        │
        ▼
auth-service generates 6-digit OTP
        │
        ├── 1. POST SSO token (client_credentials) → Bearer access_token
        └── 2. POST email/send with OTP in HTML body → employee inbox
        │
        ▼
POST /auth/verify-2fa { sessionId, code }
```

Each email request uses a **new random UUID** for `userId` (not the employee id).

---

## API endpoints (internal VPN)

| Step | URL |
|------|-----|
| SSO token | `http://10.4.3.27:9001/sso/openid-connect/v1/token` |
| Send email | `http://10.4.3.27:9001/maxit/notification/v1/email/send` |

**Requirements:** machine running auth-service must reach `10.4.3.27:9001` (Orange VPN / internal network).

---

## Environment variables

Add to **`myboss-platform/.env`** (Docker reads this for auth-service):

```env
# Enable Orange email OTP
OTP_PROVIDER=orange
TWO_FA_DEMO_ENABLED=false

# SSO (client_credentials)
ORANGE_SSO_TOKEN_URL=http://10.4.3.27:9001/sso/openid-connect/v1/token
ORANGE_SSO_CLIENT_ID=apigee-app
ORANGE_SSO_CLIENT_SECRET=<from Orange team>
ORANGE_SSO_API_KEY=<SSO apiKey header>

# Email send
ORANGE_EMAIL_API_URL=http://10.4.3.27:9001/maxit/notification/v1/email/send
ORANGE_EMAIL_CLIENT_NAME=sajelni
ORANGE_EMAIL_CHANNEL=survey_app
ORANGE_EMAIL_TYPE=blank
ORANGE_EMAIL_API_KEY=<email apiKey header>
```

| Variable | Header / body | Notes |
|----------|---------------|-------|
| `ORANGE_SSO_API_KEY` | `apiKey` on SSO request | Separate from email key |
| `ORANGE_EMAIL_API_KEY` | `apiKey` on email request | |
| `ORANGE_EMAIL_TYPE` | `blank` or `blank_ar` | Email template |
| `ORANGE_OTP_FALLBACK_DEMO` | — | If `true`, on send failure log OTP + return `demoOtpCode` (dev without VPN) |

**GitLab CI/CD:** same keys as masked protected variables — see [`ENV_AND_GITLAB_VARIABLES.md`](ENV_AND_GITLAB_VARIABLES.md).

---

## Enable on a new device

```bash
cd myboss-platform
cp .env.example .env
# Edit .env — set Orange OTP variables above (secrets from Orange team)

./scripts/deploy-demo-server.sh 127.0.0.1
# Recreate auth if already running:
docker compose -f docker/docker-compose.demo.yml up -d --force-recreate auth-service
```

Verify SSO + sign-in:

```bash
./scripts/verify-orange-otp.sh
curl -X POST http://127.0.0.1:3001/api/v1/auth/sign-in \
  -H 'Content-Type: application/json' \
  -d '{"email":"your.name@orange.com"}'
# Check inbox — no demoOtpCode in response when OTP_PROVIDER=orange
```

---

## Manual curl (debug)

**1. SSO token**

```bash
curl -X POST 'http://10.4.3.27:9001/sso/openid-connect/v1/token' \
  -H 'apiKey: YOUR_SSO_API_KEY' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: application/json;charset=utf-8' \
  -d 'grant_type=client_credentials&client_id=apigee-app&client_secret=YOUR_CLIENT_SECRET'
```

**2. Send email**

```bash
curl -X POST 'http://10.4.3.27:9001/maxit/notification/v1/email/send' \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H 'client_name: sajelni' \
  -H 'apiKey: YOUR_EMAIL_API_KEY' \
  -H 'Content-Type: application/json;charset=utf-8' \
  -H 'Accept: application/json;charset=utf-8' \
  -d '{
    "userId": "00000000-0000-0000-0000-000000099499",
    "email": "employee@orange.com",
    "type": "blank",
    "channel": "survey_app",
    "data": "{\"title\":\"MyBoss verification code\",\"content\":\"<p>Your code is: <b>123456</b></p>\"}"
  }'
```

Use a **new UUID** for `userId` on each request (auth-service does this automatically).

---

## Mobile / admin testing

When `OTP_PROVIDER=orange` and `TWO_FA_DEMO_ENABLED=false`:

- API response **does not** include `demoOtpCode`
- User must read OTP from **email**
- Mobile: do **not** rely on `DEMO_MODE` auto-fill for OTP

For local dev without VPN:

```env
OTP_PROVIDER=orange
ORANGE_OTP_FALLBACK_DEMO=true
TWO_FA_DEMO_ENABLED=true
```

Email failure falls back to console log + `demoOtpCode` in API response.

---

## Logs

```bash
docker logs myboss-auth 2>&1 | grep 'Orange OTP'
```

Look for:
- `SSO token acquired`
- `Email dispatched to user@orange.com`

---

## Code references

| File | Role |
|------|------|
| `auth-service/.../orange-sso-token.service.ts` | SSO client_credentials |
| `auth-service/.../orange-email-notification.service.ts` | Email send |
| `auth-service/.../orange-email-otp.provider.ts` | 2FA provider |
| `libs/common/src/config/app.config.ts` | `orangeOtpConfig` |

---

*Orange — my boss app*
