# Integration governance — my boss app

**Status:** Implemented in `@myboss/common` and enforced across all five microservices.  
**Audience:** Backend, mobile, admin, Apigee platform teams.

## Related docs

| Document | Purpose |
|---|---|
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | Endpoint catalogue + auth classes |
| [`../deployment/pdf/03_APIGEE_CONNECTION.md`](../deployment/pdf/03_APIGEE_CONNECTION.md) | Apigee proxy routes and policies |
| [`DATA_MODEL.md`](DATA_MODEL.md) | Target PostgreSQL schema |
| [`APIGEE_CHAT.md`](APIGEE_CHAT.md) | Chat-specific proxy notes |

## Architecture

```
Mobile / Admin  →  Apigee (or nginx gateway :8090)  →  Microservices
                         │
                         ├── /auth/api/v1/**   → auth-service   :3001
                         ├── /user/api/v1/**   → user-service   :3002
                         ├── /config/api/v1/** → config-service :3003
                         ├── /squad/api/v1/**  → squad-service  :3004
                         └── /survey/api/v1/** → survey-service :3005
```

Each service exposes:

- REST under `/api/v1`
- Swagger at `/api/v1/docs` (when `APP_ENV=development|demo` or `SWAGGER_ENABLED=true`)
- Orange Common Response errors via `HttpExceptionFilter`

## Orange error envelope

All services return errors in this shape:

```json
{
  "code": 50,
  "reason": "Access denied",
  "message": "You must join a squad before using this feature.",
  "infoURL": "https://api.orange.com/errors/50"
}
```

| Field | Source |
|---|---|
| `code` | Orange integer code (`orange-error-codes.ts`) |
| `reason` | Short English category from governance spreadsheet |
| `message` | Localized detail (`Accept-Language: en` or `ar`) |
| `infoURL` | `ORANGE_ERROR_INFO_BASE_URL/{code}` (default `https://api.orange.com/errors`) |

Internal app codes (`AppErrorCode`) map 1:1 to Orange codes in `libs/common/src/errors/orange-error-codes.ts`.

Use `throwAppError(AppErrorCode.X, HttpStatus.Y)` — never raw Nest `BadRequestException` in domain code.

## Authentication & authorization

### JWT (mobile + admin)

- Issued by `auth-service` after OTP verification
- Payload: `{ sub, email, roles: ['employee' | 'admin' | 'super_admin'] }`
- Validated globally by `JwtAuthGuard` (`@Public()` skips validation)

### Role guard

`@Roles(Role.ADMIN)` on controllers/methods. Missing or insufficient role → Orange code **50** (not silent 403).

| Role | Capabilities |
|---|---|
| `employee` | Mobile app, squad features when `squad_id` set |
| `admin` | Admin portal CRUD, analytics export, company/governorate reports |
| `super_admin` | User delete, elevated admin operations |

### Squad membership (backend enforcement)

Mobile UI gates chat/survey/gallery/reports when `squad_id` is null. Backend additionally validates:

- `POST /survey/api/v1/responses` — JWT `sub` must match `userId`; profile `squad_id` must match `squadId`
- `POST /survey/api/v1/gallery` — same
- `GET /survey/api/v1/responses/reports/squad?id={squadId}` — caller must belong to that squad
- `GET .../reports/company|governorate` — `admin` role required

Error code: `SQUAD_MEMBERSHIP_REQUIRED` → Orange **50**.

### Internal service sync

Service-to-service calls use header:

```
X-Internal-Service-Token: {INTERNAL_SERVICE_TOKEN}
```

| Route | Guard | Called by |
|---|---|---|
| `POST /user/api/v1/users/ensure` | `InternalServiceGuard` | auth-service after sign-in |
| `PUT /user/api/v1/users/:id/squad` | `InternalOrAdminGuard` | squad-service sync **or** admin JWT |

Default demo token: `demo-internal-sync` (override via env in production).

## Swagger / OpenAPI

- Built with `@nestjs/swagger` via `setupServiceSwagger()` in each service `main.ts`
- Bearer auth scheme: `bearer` (JWT)
- Server URLs include Apigee path prefix and direct dev path
- Use `@ApiOrangeErrors()` on controllers to document standard error responses
- DTO: `OrangeErrorResponseDto`

## Shared library (`@myboss/common`)

| Module | Responsibility |
|---|---|
| `SecurityModule` | Global JWT + Roles guards |
| `HttpExceptionFilter` | Orange envelope + `infoURL` |
| `throwAppError` / `AppException` | Typed domain errors |
| `InternalServiceGuard` | Service token validation |
| `InternalOrAdminGuard` | Token or admin JWT |
| `CurrentUser` | Param decorator for JWT payload |
| `ApiOrangeErrors` | Swagger error documentation |

Do **not** commit compiled `.js` files under `libs/common/src/` — TypeScript only.

## Apigee checklist

1. Create five proxies matching gateway paths (see `03_APIGEE_CONNECTION.md`)
2. Pass `Authorization` and `Accept-Language` unchanged on authenticated routes
3. Do **not** expose internal sync routes publicly without IP allowlist + service token policy
4. Spike arrest / CORS per Orange standards
5. Health: `GET /**/health` on each service

## Verification

```bash
# Gateway smoke (includes squad browse)
./infrastructure/scripts/verify-localhost.sh

# Mobile API via gateway
./infrastructure/scripts/verify-mobile-api.sh 127.0.0.1 --gateway
```

Swagger (direct): `http://localhost:3001/api/v1/docs` … `3005`.

---

*Orange — my boss app — Integration Governance*
