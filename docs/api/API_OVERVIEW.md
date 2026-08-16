# my boss app — API Overview

> Aligned with Orange Integration Governance (Build New API Guideline) and Common Response Error Codes.

## Related documentation

| Document | Description |
|---|---|
| [`../architecture/GOVERNANCE.md`](../architecture/GOVERNANCE.md) | Orange governance, errors, roles |
| [`CHAT_API.md`](CHAT_API.md) | Native squad chat — endpoints, auth, mobile flow, curl examples |
| [`SQUADS.md`](SQUADS.md) | Join, invitations (seat reservation), admin manage |
| [`../deployment/ORANGE_OTP_SETUP.md`](../deployment/ORANGE_OTP_SETUP.md) | Orange SSO + Maxit email (internal OTP) |
| [`../deployment/TESTING.md`](../deployment/TESTING.md) | QA checklist + Swagger links |

## Base URLs

One NestJS process serves every former microservice.

| Environment | Pattern | Example |
|---|---|---|
| Development (local) | `http://127.0.0.1:3001/api/v1` | `http://127.0.0.1:3001/api/v1/auth/sign-in` |
| Demo / deployed VM | `http://<SERVER_IP>:3001/api/v1` | `http://<HOST>:3001/api/v1/auth/sign-in` |

## Swagger documentation

OpenAPI when `APP_ENV=development|demo` or `SWAGGER_ENABLED=true`:

| | URL |
|---|---|
| Health | http://127.0.0.1:3001/api/v1/health |
| Swagger UI | http://127.0.0.1:3001/docs |

## Service ports

| Port | Service |
|------|---------|
| 3001 | Single API (auth, users, config, squads, surveys, gallery, notifications, push) |
| 8081 | Admin UI (Docker) |

## Verification

```bash
curl http://127.0.0.1:3001/api/v1/health
```

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

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/sign-in` | Public | Start OTP sign-in (admin must pre-register employee) |
| POST | `/auth/verify-2fa` | Public | Verify OTP → JWT tokens |
| POST | `/auth/resend-otp` | Public | Resend OTP |
| POST | `/auth/refresh` | Public | Refresh access token |
| POST | `/auth/sign-out` | JWT | Sign out |

### Users

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/users/:id` | JWT | Get profile |
| PUT | `/users/:id/onboarding` | JWT | Complete onboarding |
| PUT | `/users/:id/profile` | JWT | Update profile |
| PUT | `/users/:id/squad` | JWT | Assign squad to profile |
| POST | `/users/:id/device-token` | JWT | Register FCM device token for push |
| DELETE | `/users/:id/device-token` | JWT | Revoke device token on logout |
| POST | `/users/ensure` | Internal | Sync profile after auth |

### Squads

Join, invite, and admin rules: [`SQUADS.md`](SQUADS.md).

Pending join requests **and** invitations reserve seats: `remainingSeats = max − members − pending`. When a user joins, **all** of their join/invite rows are deleted.

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/squads/stats` | JWT | Formation statistics |
| GET | `/squads` | JWT | Search squads (summary rows) |
| GET | `/squads/admin/all` | JWT + ADMIN | Full squads with members |
| GET | `/squads/admin/unassigned-employees` | JWT + ADMIN | Registered employees with no squad |
| GET | `/squads/admin/invites` | JWT + ADMIN | Leader invitations across squads |
| POST | `/squads/admin/assign` | JWT + ADMIN | Assign unassigned employee (deletes their pending requests) |
| PUT | `/squads/admin/:id` | JWT + ADMIN | Rename squad |
| PUT | `/squads/admin/:id/leadership` | JWT + ADMIN | Transfer leadership |
| DELETE | `/squads/admin/:id/members/:memberId` | JWT + ADMIN | Remove member |
| DELETE | `/squads/admin/:id/invites/:requestId` | JWT + ADMIN | Cancel pending invite (frees seat) |
| DELETE | `/squads/admin/:id` | JWT + ADMIN | Delete squad |
| PUT | `/squads/:id/destination` | JWT + ADMIN | Set squad destination |
| GET | `/squads/my/:userId` | JWT | User's squad |
| GET | `/squads/join-status/:userId` | JWT | Join request status |
| GET | `/squads/:id/suggested-members` | JWT + leader | Invite directory (`canInvite`, `inSquadName`, `remainingSeats`) |
| GET | `/squads/:id` | JWT | Squad details |
| POST | `/squads` | JWT | Create squad (clears the leader’s pending requests) |
| POST | `/squads/:id/join` | JWT | Request to join |
| POST | `/squads/:id/invites` | JWT + leader | Invite member (uses one remaining seat) |
| PUT | `/squads/:id/invites/:requestId` | JWT | Invitee accept/reject |
| DELETE | `/squads/:id/invites/:requestId` | JWT + leader | Cancel invite (frees seat) |
| PUT | `/squads/:id/requests/:requestId` | JWT + leader | Approve/reject join |
| DELETE | `/squads/:id/members/:memberId` | JWT + leader | Remove member |
| PUT | `/squads/:id/leadership` | JWT + leader | Transfer leadership |
| POST | `/squads/:id/leave` | JWT | Leave squad |

### Surveys & gallery

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/surveys/catalog` | JWT | Active surveys for mobile home (id, segment, title, description — **no questions**) |
| GET | `/surveys/active/:segment` | JWT | Active survey by segment (**full questions**). Mobile prefetches this on Home and caches it for offline open |
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

Employee-app offline open/fill/draft is client-side: [`docs/mobile/OFFLINE_SURVEYS.md`](../mobile/OFFLINE_SURVEYS.md). `POST /responses` is still required to persist a submission; the phone queues that call when offline.

### Push dispatch

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/push/status` | Public | FCM config status (`dry-run` vs `live`) |
| POST | `/push/internal/dispatch` | Internal | Fan-out push to employee IDs |
| POST | `/push/internal/dispatch-audience` | Internal | Resolve audience → dispatch |
| GET | `/push/audit` | JWT + ADMIN | Recent push delivery audit |

Setup: [`docs/PUSH_FIREBASE_SETUP.md`](../PUSH_FIREBASE_SETUP.md)

### Config & chat

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

---

*Orange — my boss app — API Reference*
