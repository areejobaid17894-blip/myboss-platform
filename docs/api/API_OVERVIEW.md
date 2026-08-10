# my boss app — API Overview

> Aligned with Orange Integration Governance (Build New API Guideline) and Common Response Error Codes.

## Related documentation

| Document | Description |
|---|---|
| [`../architecture/GOVERNANCE.md`](../architecture/GOVERNANCE.md) | Orange governance, errors, roles, Apigee paths |
| [`CHAT_API.md`](CHAT_API.md) | Native squad chat — endpoints, auth, mobile flow, curl examples |
| [`../architecture/APIGEE_CHAT.md`](../architecture/APIGEE_CHAT.md) | Chat + Apigee proxy policies |
| [`../deployment/pdf/04_TESTING_GUIDE.md`](../deployment/pdf/04_TESTING_GUIDE.md) | QA checklist + Swagger links |

## Base URLs

| Environment | Pattern | Example |
|---|---|---|
| Development (direct) | `http://localhost:{port}/api/v1` | Auth `:3001`, User `:3002`, Config `:3003`, Squad `:3004`, Survey `:3005`, Notification `:3006` |
| Development (gateway) | `http://localhost:8090/{service}/api/v1` | `http://localhost:8090/auth/api/v1/auth/sign-in` |
| Apigee (future) | `https://api-demo.orange.com/{service}/api/v1` | Same path structure as gateway |

## Swagger documentation

Each service exposes OpenAPI (Swagger UI) when `APP_ENV=development|demo` or `SWAGGER_ENABLED=true`:

| Service | Swagger URL |
|---|---|
| Auth | http://localhost:3001/api/v1/docs |
| User | http://localhost:3002/api/v1/docs |
| Config | http://localhost:3003/api/v1/docs |
| Squad | http://localhost:3004/api/v1/docs |
| Survey | http://localhost:3005/api/v1/docs |
| Notification | http://localhost:3006/api/v1/docs |

Via gateway (same paths under each prefix): `http://localhost:8090/auth/api/v1/docs`, etc.

## Authentication classification

| Class | Endpoints | Auth |
|---|---|---|
| **Public** | `POST /auth/sign-in`, `/verify-2fa`, `/resend-otp`, `/refresh`, `/admin-sign-in` | None |
| **Public** | `GET /config/buildings`, `/config/segments`, `/config/employee-settings`, `GET /chat/config`, `GET /chat/health`, `GET /health` | None |
| **Internal** | `POST /users/ensure`, `PUT /users/:id/squad` | `X-Internal-Service-Token` header (service sync) or JWT + `ADMIN` for squad assign |
| **JWT required** | All other mobile endpoints | `Authorization: Bearer {accessToken}` |
| **Admin** | User CRUD, survey CRUD, config writes, analytics, company/governorate reports | JWT + `admin` role |
| **Squad member** | Survey submit, gallery upload, squad-scoped reports | JWT + active `squad_id` on profile |

## Orange error response format

All services return errors in Orange Common Response format:

```json
{
  "code": 41,
  "reason": "Invalid credentials",
  "message": "Invalid or expired verification code.",
  "infoURL": "https://api.orange.com/errors/41"
}
```

| HTTP | Orange Code | Reason |
|---|---|---|
| 400 | 20–28 | Validation errors |
| 401 | 40 | Missing credentials |
| 401 | 41 | Invalid credentials |
| 401 | 42 | Expired credentials |
| 403 | 50 | Access denied |
| 404 | 60 | Resource not found |
| 409 | 69 | Conflict |
| 500 | 1 | Internal error |

## Mobile-facing endpoints

### Auth (`auth-service`)

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/sign-in` | Public | Start OTP sign-in (admin must pre-register employee) |
| POST | `/auth/verify-2fa` | Public | Verify OTP → JWT tokens |
| POST | `/auth/resend-otp` | Public | Resend OTP |
| POST | `/auth/refresh` | Public | Refresh access token |
| POST | `/auth/sign-out` | JWT | Sign out |

### Users (`user-service`)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/users/:id` | JWT | Get profile |
| PUT | `/users/:id/onboarding` | JWT | Complete onboarding |
| PUT | `/users/:id/profile` | JWT | Update profile |
| PUT | `/users/:id/squad` | JWT | Assign squad to profile |
| POST | `/users/:id/device-token` | JWT | Register FCM device token for push |
| DELETE | `/users/:id/device-token` | JWT | Revoke device token on logout |
| POST | `/users/ensure` | Internal | Sync profile after auth |

### Squads (`squad-service`)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/squads/stats` | JWT | Formation statistics |
| GET | `/squads` | JWT | Search squads (summary rows) |
| GET | `/squads/admin/all` | JWT + ADMIN | Full squads with members |
| POST | `/squads/admin/assign` | JWT + ADMIN | Admin assign employee |
| PUT | `/squads/:id/destination` | JWT + ADMIN | Set squad destination |
| GET | `/squads/my/:userId` | JWT | User's squad |
| GET | `/squads/join-status/:userId` | JWT | Join request status |
| GET | `/squads/:id` | JWT | Squad details |
| POST | `/squads` | JWT | Create squad |
| POST | `/squads/:id/join` | JWT | Request to join |
| PUT | `/squads/:id/requests/:requestId/:leaderId` | JWT | Approve/reject join |

### Surveys & gallery (`survey-service`)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/surveys/catalog` | JWT | Active surveys for mobile home |
| GET | `/surveys/active/:segment` | JWT | Active survey by segment |
| GET | `/surveys/:id` | JWT | Survey by ID |
| POST | `/responses` | JWT + squad | Submit survey response |
| GET | `/responses/progress/:squadId` | JWT | Squad progress |
| GET | `/responses/reports/squad` | JWT + squad | Squad reports (caller must belong to `?id=squadId`) |
| GET | `/responses/reports/company` | JWT + ADMIN | Company-wide reports |
| GET | `/responses/reports/governorate` | JWT + ADMIN | Governorate reports |
| GET | `/gallery` | JWT | List gallery items (announcements + employee media) |
| GET | `/gallery?source=employee` | JWT + ADMIN | Employee uploads only (admin Photos) |
| POST | `/gallery` | JWT + squad | Upload gallery item (`source=employee`) |
| POST | `/notifications` | JWT + ADMIN | Compose notification → gallery announcement + inbox |
| GET | `/notifications/history` | JWT + ADMIN | Admin sent history |
| GET | `/notifications/for-user` | JWT | Employee inbox (audience-filtered, includes `imageUrl`) |
| GET | `/notifications/:id` | JWT | Full notification detail (`?userId=`) |
| POST | `/notifications/:id/read` | JWT | Mark notification read |

See [`docs/architecture/GALLERY_NOTIFICATIONS.md`](../architecture/GALLERY_NOTIFICATIONS.md) for the unified gallery ↔ notifications model.

### Push dispatch (`notification-service`)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/push/status` | Public | FCM config status (`dry-run` vs `live`) |
| POST | `/push/internal/dispatch` | Internal | Fan-out push to employee IDs |
| POST | `/push/internal/dispatch-audience` | Internal | Resolve audience → dispatch |
| GET | `/push/audit` | JWT + ADMIN | Recent push delivery audit |

Setup: [`docs/PUSH_FIREBASE_SETUP.md`](../PUSH_FIREBASE_SETUP.md)

### Config & chat (`config-service`)

Full chat documentation: [`docs/api/CHAT_API.md`](CHAT_API.md)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/config/buildings` | Public | Building list (onboarding) |
| GET | `/chat/config` | Public | Chat bootstrap metadata |
| GET | `/chat/health` | Public | Chat monitoring |
| GET | `/chat/visitor` | JWT | Authenticated user identity for chat |
| GET | `/chat/messages?peerId=` | JWT | List direct messages (poll) |
| POST | `/chat/messages` | JWT | Send direct message to squad peer |

**Mobile chat rules:** squad members only; requires active squad; native UI (no external widget).

## Apigee proxy routes

See `docs/deployment/pdf/03_APIGEE_CONNECTION.md` for proxy setup:

- `/auth/api/v1/**` → auth-service
- `/user/api/v1/**` → user-service
- `/config/api/v1/**` → config-service
- `/squad/api/v1/**` → squad-service
- `/survey/api/v1/**` → survey-service

## Verification

```bash
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

---

*Orange — my boss app — API Reference*
