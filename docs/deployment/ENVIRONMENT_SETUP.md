# my boss app — Environment Setup Guide

Local development setup for all applications. For production/demo deployment, use [`../devops/DEVOPS.md`](../devops/DEVOPS.md).

---

## Prerequisites

| Tool | Version | Guide |
|------|---------|-------|
| Node.js | **20 LTS** | [nodejs.org](https://nodejs.org/) |
| Flutter | **3.35.7** (FVM) | [`../mobile/ANDROID_STUDIO.md`](../mobile/ANDROID_STUDIO.md) |
| Docker | 24+ Compose v2 | [`../devops/DEVOPS.md`](../devops/DEVOPS.md) |
| Android Studio | Latest | [`../mobile/ANDROID_STUDIO.md`](../mobile/ANDROID_STUDIO.md) |
| Git | Latest | — |

---

## 1. Repository

```bash
git clone <repository-url> my_boss_v5
cd my_boss_v5
cp .env.example .env
```

Edit `.env` — see [`.env.example`](../../.env.example). Required: `JWT_SECRET`, optionally `INTERNAL_SERVICE_TOKEN`.

---

## 2. Backend (local dev)

```bash
cd apps/backend
npm install
npm run start:dev    # all services :3001–3005
```

Verify:
- http://localhost:3001/api/v1/docs (Swagger)
- http://localhost:3001/api/v1/health

Details: [`apps/backend/README.md`](../../apps/backend/README.md)

---

## 3. Admin portal

```bash
cd apps/admin-portal
npm install
npm run dev
```

Open http://localhost:5173 (or gateway http://127.0.0.1:8090/login when demo stack running).

---

## 4. Mobile app

```bash
cd apps/mobile
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter run --dart-define=DEMO_MODE=true
```

Full Android Studio guide: [`../mobile/ANDROID_STUDIO.md`](../mobile/ANDROID_STUDIO.md)

---

## 5. Optional: PostgreSQL & Redis

```bash
cd infrastructure/docker
docker compose up -d
```

Demo backend uses in-memory stores; DB schema target: [`../database/DATABASE.md`](../database/DATABASE.md).

---

## 6. Environments

| `APP_ENV` | Swagger | 2FA |
|-----------|---------|-----|
| development | On | Demo |
| demo | On | Demo |
| uat | Configurable | TBD |
| production | Off | Production provider |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Port conflicts | Change ports in `.env` (3001–3005, 5173) |
| Flutter build | `fvm flutter clean && fvm flutter pub get` |
| DB connection | Ensure Docker postgres running; match `.env` credentials |

---

## Related docs

| Document | Purpose |
|----------|---------|
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Docker demo deploy |
| [`../security/SECURITY.md`](../security/SECURITY.md) | Secrets & auth |
| [`../README.md`](../README.md) | Documentation index |

---

*Orange — my boss app*
