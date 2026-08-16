# my boss app — Architecture Documentation

> **Current local/runtime summary:** see [`../../README.md`](../../README.md).  
> Local clients call one NestJS API on **:3001** (no Apigee). Data store: **MySQL 8** — development and production share `my_boss` on `10.1.165.105:3308`; preprod (staging) uses a dedicated DB. OTP: development and production use production Maxit; preprod uses preprod SSO/email. See [`../deployment/STAGES.md`](../deployment/STAGES.md).

## 1. System Context

The platform serves two user groups:

| User Group | Application | Access |
|---|---|---|
| Employees | Flutter Mobile App | Mobile / employee web |
| Administrators | Web Admin Portal | Browser |

Local and current demo path: clients talk to the **single NestJS API** on `:3001`. Apigee may be used later as an external gateway in some deployments.

## 2. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│  ┌─────────────────────┐    ┌──────────────────────────┐    │
│  │  Flutter Mobile App │    │  Admin Portal (React)    │    │
│  └──────────┬──────────┘    └────────────┬─────────────┘    │
└─────────────┼──────────────────────────────┼──────────────────┘
              │                              │
              └──────────────┬───────────────┘
                             │ HTTP :3001 /api/v1
┌────────────────────────────▼─────────────────────────────────┐
│              Single NestJS API (myboss-api)                  │
│  auth · users · config · squads · surveys · gallery · push   │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│  MySQL 8 — database my_boss (shared across stages)            │
└──────────────────────────────────────────────────────────────┘
```

## 3. Backend — Single API

Former microservice folders still exist in `myboss-backend` as Nest modules, compiled into **one process** (`myboss-api`, port **3001**).

### 3.1 Module boundaries

| Module | Responsibility | Port |
|---|---|---|
| **auth** | Authentication, JWT, Orange OTP | 3001 (same process) |
| **users** | User CRUD, profiles, roles | 3001 |
| **config** | App configuration, business settings, squad limits | 3001 |
| **squads** | Squads, members, join requests, invitations | 3001 |
| **surveys** | Surveys, gallery, in-app notifications | 3001 |
| **push** | FCM dispatch | 3001 |

Modules are compiled into **one Docker image** (`myboss-api`). They remain independently testable in `myboss-backend`. All modules share **one MySQL database** (`my_boss`) with real foreign keys — see [`../database/DATABASE.md`](../database/DATABASE.md).

### 3.2 Internal Architecture (per service)

```
src/
├── main.ts                    # Bootstrap
├── app.module.ts              # Root module
├── config/                    # Environment configuration
├── modules/
│   └── <feature>/
│       ├── <feature>.module.ts
│       ├── <feature>.controller.ts    # Presentation
│       ├── <feature>.service.ts       # Business logic
│       ├── <feature>.repository.ts    # Data access
│       ├── dto/                       # Data transfer objects
│       └── entities/                  # Database entities
├── common/                    # Filters, guards, interceptors, pipes
└── infrastructure/            # Database, external integrations
```

### 3.3 Cross-Cutting Concerns

| Concern | Implementation |
|---|---|
| Authentication | JWT guards, OAuth2 strategy (Passport) |
| Authorization | Role-based guards |
| Validation | class-validator DTOs |
| Logging | Structured JSON logging |
| Health checks | `@nestjs/terminus` |
| API docs | Swagger/OpenAPI per service |
| Error handling | Global exception filter |

### 3.4 Demo 2FA — Replaceable Design

The demo 2FA is implemented behind an abstraction:

```
ITwoFactorProvider (interface)
├── DemoTwoFactorProvider    ← Current (temporary)
└── ProductionTwoFactorProvider  ← Future (swap via DI)
```

Replacing demo 2FA requires only:
1. Implement `ITwoFactorProvider`
2. Update DI binding in `AuthModule`
3. Update environment configuration

## 4. Flutter Mobile App

### 4.1 Layer Architecture

```
lib/
├── app/                 # App widget, router, theme
├── core/                # Shared infrastructure
│   ├── config/          # Environment config
│   ├── di/              # Dependency injection (get_it + injectable)
│   ├── network/         # Dio client, interceptors
│   ├── storage/         # Secure storage wrapper
│   ├── localization/    # Phrase integration, l10n
│   ├── theme/           # App theme, RTL support
│   └── error/           # Failure types, exceptions
├── features/            # Feature modules
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/    # Remote & local data sources
│       │   ├── models/         # DTOs (freezed + json_serializable)
│       │   └── repositories/   # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Business entities
│       │   ├── repositories/   # Repository interfaces
│       │   └── usecases/       # Business use cases
│       └── presentation/
│           ├── bloc/           # BLoC (events, states)
│           ├── pages/          # Screens
│           └── widgets/        # Feature-specific widgets
└── main.dart
```

### 4.2 State Management

- **BLoC** (`flutter_bloc`) for all feature state
- **Repository pattern** for data access
- **Use cases** for business logic orchestration
- **Dependency injection** via `get_it` + `injectable`

### 4.3 Localization

- **Phrase Strings** for translation management
- Generated l10n files via `flutter gen-l10n` + Phrase CLI
- RTL/LTR automatic switching based on locale
- No hardcoded user-facing strings

### 4.4 Offline surveys

On Home (online) the app caches full survey schemas plus the last profile/squad. Offline, employees can open those services, fill them, and close to save a draft. Queued submissions flush when Home loads online. See [`../mobile/OFFLINE_SURVEYS.md`](../mobile/OFFLINE_SURVEYS.md).

## 5. Admin Portal — the Boss Admin Console (V2)

### 5.1 Architecture

```
src/
├── api/                 # Axios clients (auth, user, squad, survey, config, gallery)
├── components/admin/    # Charts (DonutChart, HBarChart), ErrorBoundary
├── hooks/               # useAdminData, useAuditLog, useToast
├── layouts/             # AdminLayout — black sidebar V2
├── pages/               # 11 journey sections + Configuration
├── lib/                 # adminGeo, csvExport, demo localStores
├── router/              # React Router v7
└── styles/              # admin-console.css
```

### 5.2 Tech stack

- React 19 + TypeScript
- Vite 6
- React Router 7
- Axios (JWT interceptors)
- CSS modules + `admin-console.css` (Inter font, Orange V2 theme)

### 5.3 Key API integrations

| Admin action | Backend |
|--------------|---------|
| List squads with members | `GET /squads/admin/all` |
| Assign employee | `POST /squads/admin/assign` → writes `squad_members` (same shared DB) |
| Rename / make leader / remove / delete | `PUT/DELETE /squads/admin/:id…` |
| Leader invitations monitor | `GET /squads/admin/invites` · Cancel `DELETE /squads/admin/:id/invites/:requestId` |
| Save destination | `PUT /squads/:id/destination` |
| Users / surveys / gallery / notifications | Same API origin `:3001` |

Seat reservation, join cleanup, and invite rules: [`../api/SQUADS.md`](../api/SQUADS.md).

## 6. Security Architecture

| Layer | Mechanism |
|---|---|
| Transport | TLS 1.2+ (HTTPS everywhere) |
| Authentication | JWT (access + refresh tokens) |
| Authorization | Role-based access control (RBAC) |
| Token storage (mobile) | Flutter Secure Storage |
| Token storage (web) | HttpOnly secure cookies |
| API security | Input validation, rate limiting (Apigee), CORS |
| Mobile security | Certificate pinning (configurable), root/jailbreak detection (future) |

## 7. Environment Strategy

| Config | Development | Demo | UAT | Production |
|---|---|---|---|---|
| Debug logging | Yes | Yes | Limited | No |
| Demo 2FA | Yes | Yes | No | No |
| Swagger UI | Yes | Yes | Yes | No |
| Hot reload | Yes | No | No | No |

Configuration is loaded from environment variables — never hardcoded.

## 8. CI/CD Pipeline

See [`../devops/DEVOPS.md`](../devops/DEVOPS.md) and [`.gitlab-ci.yml`](../../.gitlab-ci.yml) for pipeline details.

Each application has independent pipelines:
- Lint → Test → Build → Deploy (Demo)

## 9. Reporting Readiness

Backend models include:
- Audit timestamps (`createdAt`, `updatedAt`)
- Soft delete support where applicable
- Structured entities suitable for Power BI export
- Dedicated reporting endpoints (to be defined with business requirements)

## 10. Apigee Readiness

Services expose:
- Standard REST endpoints with versioning (`/api/v1/...`)
- Health check endpoints (`/health`)
- OpenAPI/Swagger specs
- Stateless design (JWT, no server-side sessions)
- Consistent error response format

Apigee will handle: routing, rate limiting, analytics, API key management, OAuth validation.

---

*This document will be updated as business requirements are finalized.*
