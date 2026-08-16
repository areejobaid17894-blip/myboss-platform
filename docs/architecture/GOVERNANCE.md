# Integration governance — my boss app

**Status:** Implemented in `@myboss/common` and enforced on the single NestJS API.  
**Audience:** Backend, mobile, admin, Apigee platform teams.

## Related docs

| Document | Purpose |
|---|---|
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | Endpoint catalogue + auth classes |
| [`../deployment/APIGEE_CONNECTION.md`](../deployment/APIGEE_CONNECTION.md) | Apigee proxy routes and policies |
| [`../database/DATABASE.md`](../database/DATABASE.md) | MySQL schema (`my_boss`) |
| [`APIGEE_CHAT.md`](APIGEE_CHAT.md) | Chat-specific proxy notes |

## Architecture

```
Mobile / Admin  →  myboss-api :3001 /api/v1/**
                         │
                         ├── /auth/**
                         ├── /users/**
                         ├── /config/**  /chat/**
                         ├── /squads/**
                         ├── /surveys/**  /gallery/**  /notifications/**
                         └── /push/**
```

**Runtime:** one API (`:3001`) and one admin SPA (`:8081`). No nginx and no extra microservice ports. Optional future Apigee gateway in front of `:3001`.

The API exposes:

- REST under `/api/v1`
- Swagger at `http://127.0.0.1:3001/docs` (when `APP_ENV=development|demo|preprod` or `SWAGGER_ENABLED=true`)
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
| `POST /users/ensure` | `InternalServiceGuard` | Auth module after sign-in |
| `PUT /users/:id/squad` | `InternalOrAdminGuard` | Squad module sync **or** admin JWT |

Default demo token: `demo-internal-sync` (override via env in production).

## Swagger / OpenAPI

- Built with `@nestjs/swagger` on the single API (`http://127.0.0.1:3001/docs`)
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

1. Create one proxy to `myboss-api :3001` (see `APIGEE_CONNECTION.md` if Apigee is used)
2. Pass `Authorization` and `Accept-Language` unchanged on authenticated routes
3. Do **not** expose internal sync routes publicly without IP allowlist + service token policy
4. Spike arrest / CORS per Orange standards
5. Health: `GET /api/v1/health`

## Verification

```bash
curl http://127.0.0.1:3001/api/v1/health
curl http://127.0.0.1:3001/docs
```

Swagger: `http://127.0.0.1:3001/docs`.

---

*Orange — my boss app — Integration Governance*
