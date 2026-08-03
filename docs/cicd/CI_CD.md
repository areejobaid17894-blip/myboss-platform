# my boss app — CI/CD Documentation

## Pipeline Overview

Each application has an independent CI/CD pipeline triggered on push/PR to relevant paths.

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   Mobile    │   │   Backend   │   │   Admin     │
│   Pipeline  │   │   Pipeline  │   │   Pipeline  │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       ▼                 ▼                 ▼
   Lint & Analyze   Lint & Test      Lint & Test
       │                 │                 │
       ▼                 ▼                 ▼
   Unit Tests       Unit Tests       Unit Tests
       │                 │                 │
       ▼                 ▼                 ▼
   Widget Tests     Build Images     Build Static
       │                 │                 │
       ▼                 ▼                 ▼
   Build APK/IPA    Push to Registry  Deploy Demo
```

## Workflows

| Workflow | Trigger | Path Filter |
|---|---|---|
| `mobile-ci.yml` | Push/PR to `main`, `develop` | `myboss-mobile/**` |
| `backend-ci.yml` | Push/PR to `main`, `develop` | `myboss-backend/**` |
| `admin-portal-ci.yml` | Push/PR to `main`, `develop` | `myboss-admin/**` |

## Mobile Pipeline (`mobile-ci.yml`)

| Stage | Action |
|---|---|
| Setup | Flutter SDK, dependencies |
| Analyze | `flutter analyze` |
| Unit Tests | `flutter test` |
| Widget Tests | `flutter test test/widget/` |
| Build | `flutter build apk --debug` (validation) |
| Deploy Demo | On merge to `develop` (future) |

## Backend Pipeline (`backend-ci.yml`)

| Stage | Action |
|---|---|
| Setup | Node.js, npm install |
| Lint | ESLint |
| Unit Tests | Jest per service |
| Integration Tests | Supertest against test DB |
| Build | Docker image build (validation) |
| Deploy Demo | On merge to `develop` (future) |

## Admin Portal Pipeline (`admin-portal-ci.yml`)

| Stage | Action |
|---|---|
| Setup | Node.js, npm install |
| Lint | ESLint |
| Type Check | `tsc --noEmit` |
| Unit Tests | Vitest |
| Build | `npm run build` |
| Deploy Demo | On merge to `develop` (future) |

## Branch Strategy

| Branch | Purpose | Deploys to |
|---|---|---|
| `main` | Production-ready code | Production (manual) |
| `develop` | Integration branch | Demo (auto) |
| `feature/*` | Feature development | None (CI only) |
| `release/*` | Release preparation | UAT (manual) |
| `hotfix/*` | Production fixes | Production (manual) |

## Required Secrets (GitHub Actions)

| Secret | Used By |
|---|---|
| `DOCKER_REGISTRY_URL` | Backend |
| `DOCKER_REGISTRY_USERNAME` | Backend |
| `DOCKER_REGISTRY_PASSWORD` | Backend |
| `DEMO_DEPLOY_KEY` | All (Demo deployment) |
| `PHRASE_ACCESS_TOKEN` | Mobile (localization) |

## Local CI Validation

Run the same checks locally before pushing:

```bash
# Backend
cd myboss-backend && npm run lint && npm test

# Admin Portal
cd myboss-admin && npm run lint && npm test && npm run build

# Mobile
cd myboss-mobile && flutter analyze && flutter test
```

---

*Deployment targets and credentials to be configured once company infrastructure is confirmed.*
