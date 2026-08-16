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

## API endpoints

See [`STAGES.md`](STAGES.md) for which stage uses which URLs.

| Stage | When | SSO token | Send email | Database |
|-------|------|-----------|------------|----------|
| **Development + production** | `APP_ENV=development` or `production`, or `ORANGE_OTP_ENV=production` | `http://10.4.3.27:9001/sso/openid-connect/v1/token` | `http://10.4.3.27:9001/maxit/notification/v1/email/send` | Production MySQL (`10.1.165.105:3308` / `my_boss`) |
| **Preprod (staging)** | `APP_ENV=preprod` or `ORANGE_OTP_ENV=preprod` | `http://10.1.112.95:9001/sso/openid-connect/v1/token` | `http://preprod-notification.xyz.jt.jtgroup/email/send` | Dedicated preprod DB (fill `MYSQL_*` when provided) |

Explicit `ORANGE_SSO_TOKEN_URL` / `ORANGE_EMAIL_API_URL` override the defaults.

**Hosts (preprod email hostname only)** — Windows: `C:\Windows\System32\drivers\etc\hosts`:

```
10.1.112.95 preprod-notification.xyz.jt.jtgroup
```

Docker Compose maps that hostname inside `myboss-api` via `extra_hosts`. Production Maxit is `10.4.3.27:9001`.

---

## Environment variables

Add to **`myboss-platform/.env`** (copy `.env.development.example` or `.env.production.example`; Docker reads `.env`):

```env
OTP_PROVIDER=orange
TWO_FA_DEMO_ENABLED=false
ORANGE_OTP_ENV=production

ORANGE_SSO_TOKEN_URL=http://10.4.3.27:9001/sso/openid-connect/v1/token
ORANGE_SSO_CLIENT_ID=apigee-app
ORANGE_SSO_CLIENT_SECRET=<production secret from Orange>
ORANGE_SSO_API_KEY=<SSO apiKey header>

ORANGE_EMAIL_API_URL=http://10.4.3.27:9001/maxit/notification/v1/email/send
ORANGE_EMAIL_CLIENT_NAME=sajelni
ORANGE_EMAIL_CHANNEL=survey_app
ORANGE_EMAIL_TYPE=blank
ORANGE_EMAIL_API_KEY=<email apiKey header>
```

For **preprod / staging** copy `.env.preprod.example` → `.env`, set `ORANGE_OTP_ENV=preprod`, and fill the dedicated MySQL when DBA provides it. URLs: [`STAGES.md`](STAGES.md).

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
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
```

Verify SSO + sign-in:

```bash
curl -X POST http://127.0.0.1:3001/api/v1/auth/sign-in \
  -H 'Content-Type: application/json' \
  -d '{"email":"your.name@orange.com"}'
# Check inbox — no demoOtpCode in response when OTP_PROVIDER=orange
```

---

## Manual curl (debug)

These match `orange-sso-token.service.ts` and `orange-email-notification.service.ts`. Requires VPN to `10.4.3.27`. Substitute secrets from `myboss-platform/.env` (`ORANGE_SSO_*`, `ORANGE_EMAIL_API_KEY`). Do **not** commit secrets.

OTP expiry in the email body is **10 minutes** (`OTP_EXPIRY_SECONDS = 600`).

**1. SSO token** (production — used by development and production)

```bash
curl -X POST 'http://10.4.3.27:9001/sso/openid-connect/v1/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: application/json;charset=utf-8' \
  -H 'apiKey: YOUR_SSO_API_KEY' \
  -d 'grant_type=client_credentials&client_id=apigee-app&client_secret=YOUR_PRODUCTION_CLIENT_SECRET'
```

**2. Maxit email** (production)

```bash
curl -X POST 'http://10.4.3.27:9001/maxit/notification/v1/email/send' \
  -H 'Content-Type: application/json;charset=utf-8' \
  -H 'Accept: application/json;charset=utf-8' \
  -H 'client_name: sajelni' \
  -H 'apiKey: YOUR_EMAIL_API_KEY' \
  -H 'Authorization: Bearer PASTE_ACCESS_TOKEN_HERE' \
  -d '{
    "userId": "00000000-0000-0000-0000-000000099499",
    "email": "employee@orange.com",
    "type": "blank",
    "channel": "survey_app",
    "data": "{\"title\":\"MyBoss verification code\",\"content\":\"<p>Your verification code is: <b>123456</b></p><p>This code expires in 10 minutes.</p>\"}"
  }'
```

Preprod curls use `http://10.1.112.95:9001/sso/openid-connect/v1/token` and `http://preprod-notification.xyz.jt.jtgroup/email/send` with the **preprod** client secret.

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
docker logs myboss-api 2>&1 | grep 'Orange OTP'
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
