# my boss app — Environment Setup Guide

Local development setup for all applications in the **multi-repo** layout. For production/demo deployment, use [`../devops/DEVOPS.md`](../devops/DEVOPS.md).

---

## Repository layout

Clone all four repos as **siblings**:

```
myboss-repos/
├── myboss-mobile/
├── myboss-admin/
├── myboss-backend/
└── myboss-platform/    ← docs + deploy scripts live here
```

See [`../../../README.md`](../../../README.md) in the parent folder for the full step-by-step guide.

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

## 1. Environment files

**Platform** (Docker deploy):

```bash
cd myboss-platform
cp .env.example .env
# JWT_SECRET, INTERNAL_SERVICE_TOKEN
```

**Backend** (local npm dev):

```bash
cd myboss-backend
cp .env.example .env
```

**Admin** (Vite dev):

```bash
cd myboss-admin
cp .env.example .env.development
```

---

## 2. Full demo stack (fastest)

```bash
cd myboss-platform
chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
```

- Mobile: http://127.0.0.1:8090/app/
- Admin: http://127.0.0.1:8090/login

---

## 3. Backend (local dev, no Docker)

```bash
cd myboss-backend
npm install
npm run build -w @myboss/common
npm run start:dev
```

Verify: http://localhost:3001/api/v1/docs

Details: [`../../../myboss-backend/README.md`](../../../myboss-backend/README.md) *(sibling repo)*

---

## 4. Admin portal (Vite)

```bash
cd myboss-admin
npm install
npm run dev
```

Open http://localhost:5173

---

## 5. Mobile app (Flutter)

```bash
cd myboss-mobile
fvm install 3.35.7
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter run --dart-define=DEMO_MODE=true
```

Full Android Studio guide: [`../mobile/ANDROID_STUDIO.md`](../mobile/ANDROID_STUDIO.md)

---

## 6. Optional: PostgreSQL & Redis

```bash
cd myboss-platform/docker
docker compose up -d
```

Demo backend uses in-memory stores; DB schema target: [`../database/DATABASE.md`](../database/DATABASE.md).

---

## 7. Environments

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
| Port conflicts | Change ports in `.env` (3001–3005, 5173, 8090) |
| Flutter build | `fvm flutter clean && fvm flutter pub get` |
| Gateway 502 | Wait 30s after first Docker build; run `./scripts/verify-backend.sh` |
| Sibling repos not found | Export `MYBOSS_BACKEND_DIR`, `MYBOSS_ADMIN_DIR`, `MYBOSS_MOBILE_DIR` |

---

*Orange — my boss app*
