# Environment variables & GitLab CI/CD

Same **key names** on development, preprod (staging), and production. Only values change.

| Stage | Run template | GitLab template |
|-------|--------------|-----------------|
| Development | [`../../.env.development.example`](../../.env.development.example) | [`../devops/gitlab-development.env.example`](../devops/gitlab-development.env.example) |
| Production | [`../../.env.production.example`](../../.env.production.example) | [`../devops/gitlab-production.env.example`](../devops/gitlab-production.env.example) |
| Preprod (staging) | [`../../.env.preprod.example`](../../.env.preprod.example) | [`../devops/gitlab-preprod.env.example`](../devops/gitlab-preprod.env.example) |

Laptop: copy a stage file → `.env` (for example `copy .env.development.example .env`).  
Server: GitLab **Settings → CI/CD → Variables** (mask secrets). DevOps CI/CD writes the runtime `.env`.

Two containers: `myboss-api` (:3001) and `myboss-admin` (:8081). Both read the same `.env`. Admin Vite URLs are **build-time** (`DEMO_HOST`).

---

## Stages

| | Development | Production | Preprod (staging) |
|--|-------------|------------|-------------------|
| `APP_ENV` | `development` | `production` | `preprod` |
| MySQL | `10.1.165.105:3308` / `my_boss` | **same as development** | dedicated preprod DB (fill later) |
| `ORANGE_OTP_ENV` | `production` | `production` | `preprod` |
| SSO | `http://10.4.3.27:9001/sso/openid-connect/v1/token` | **same as development** | `http://10.1.112.95:9001/sso/openid-connect/v1/token` |
| Email | `http://10.4.3.27:9001/maxit/notification/v1/email/send` | **same as development** | `http://preprod-notification.xyz.jt.jtgroup/email/send` |
| `DEMO_HOST` | `127.0.0.1` or laptop LAN | prod hostname/IP | preprod hostname/IP |
| `ADMIN_BUILD_MODE` | `demo` | `production` | `production` |
| `VITE_APP_ENV` | `development` | `production` | `preprod` |
| `TWO_FA_DEMO_ENABLED` | `false` | `false` | `false` |
| `MYSQL_CONNECTION_LIMIT` | `1` | `1` | `1` |
| `DB_SYNCHRONIZE` | `false` | `false` | `false` |

Details: [`STAGES.md`](STAGES.md) · OTP curls: [`ORANGE_OTP_SETUP.md`](ORANGE_OTP_SETUP.md).

---

## Mask in GitLab

`MYSQL_PASSWORD`, `JWT_SECRET`, `INTERNAL_SERVICE_TOKEN`, `ORANGE_SSO_CLIENT_SECRET`, `ORANGE_SSO_API_KEY`, `ORANGE_EMAIL_API_KEY`, `DEMO_ADMIN_PASSWORD`.

Optional File variable `FCM_SERVICE_ACCOUNT_JSON` for push.

---

## Admin (Vite)

Local: `myboss-admin/.env.development` (from `.env.example`).  
Docker: bake `DEMO_HOST` / `VITE_APP_ENV` at image build.

All `VITE_*_API_URL` values are `http://<host>:3001/api/v1`.

---

## Mobile

No `.env`. Use `--dart-define=API_HOST=<host>` (and `API_PORT=3001`). See `myboss-mobile/README.md`.
