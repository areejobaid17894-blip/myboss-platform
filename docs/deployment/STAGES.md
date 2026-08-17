# Stages — API, database, OTP

**Runtime:** two processes only.

| Process | Role | Port |
|---------|------|------|
| `myboss-api` | Employee + admin backend (auth, users, config, squads, surveys, gallery, push) | **3001** |
| `myboss-admin` | Admin web UI (static SPA) | **8081** |

Employees (Flutter) and the admin portal both call **one** API: `http://<HOST>:3001/api/v1`. There are no separate user/squad/survey/notification containers.

---

## Env files

Copy one file to `myboss-platform/.env`, then `docker compose up -d --build`.

| Stage | Committed template | GitLab template |
|-------|--------------------|-----------------|
| Development | [`.env.development.example`](../../.env.development.example) | [`gitlab-development.env.example`](../devops/gitlab-development.env.example) |
| Production | [`.env.production.example`](../../.env.production.example) | [`gitlab-production.env.example`](../devops/gitlab-production.env.example) |
| Preprod (staging) | [`.env.preprod.example`](../../.env.preprod.example) | [`gitlab-preprod.env.example`](../devops/gitlab-preprod.env.example) |

Filled local copies (gitignored): `.env.development`, `.env.production`, `.env.preprod`.

---

## Environments

| Stage | `APP_ENV` | MySQL | Orange SSO + Maxit |
|-------|-----------|-------|---------------------|
| **Development** | `development` | Production DB (`10.1.165.105:3308` / `my_boss`) | **Production** (`10.4.3.27`) |
| **Production** | `production` | **Same** production DB | **Same** production Maxit (`10.4.3.27`) |
| **Preprod (staging)** | `preprod` | Dedicated preprod DB (`10.1.169.88:3308` / `my_boss_pre` / `my_boss_app_pre`) | **Preprod APIs** (SSO `10.1.112.95`, email `preprod-notification.xyz.jt.jtgroup`) |

Force OTP independently of `APP_ENV` with `ORANGE_OTP_ENV=production` or `preprod`.

### Production Maxit (dev + prod — same settings)

| | URL |
|--|-----|
| SSO | `http://10.4.3.27:9001/sso/openid-connect/v1/token` |
| Email | `http://10.4.3.27:9001/maxit/notification/v1/email/send` |
| `ORANGE_SSO_CLIENT_ID` | `apigee-app` |
| `ORANGE_EMAIL_CLIENT_NAME` | `sajelni` |
| `ORANGE_EMAIL_CHANNEL` | `survey_app` |
| `ORANGE_EMAIL_TYPE` | `blank` |

### Preprod Maxit (staging only)

| | URL |
|--|-----|
| SSO | `http://10.1.112.95:9001/sso/openid-connect/v1/token` |
| Email | `http://preprod-notification.xyz.jt.jtgroup/email/send` |
| `ORANGE_SSO_CLIENT_ID` | `apigee-app` |
| `ORANGE_EMAIL_CLIENT_NAME` | `sajelni` |
| `ORANGE_EMAIL_CHANNEL` | `survey_app` |
| `ORANGE_EMAIL_TYPE` | `blank` |

Hosts (preprod email hostname, API host only):

```
10.1.112.95 preprod-notification.xyz.jt.jtgroup
```

OTP curl examples: [`ORANGE_OTP_SETUP.md`](ORANGE_OTP_SETUP.md).

---

## Public test (cellular)

Rebuild with `DEMO_HOST=<public-ip>` then `docker compose up -d --build`. Build the APK with `--dart-define=API_HOST=<public-ip>`. Publish **3001** (and **8081** for admin).

---

*Orange — my boss app*
