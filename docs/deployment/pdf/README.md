# Deployment PDF Guides

Printable / shareable guides. **Canonical sources** live in structured folders; PDF folder files may be short redirects.

## Canonical guides (maintained here)

| Topic | Canonical doc |
|-------|---------------|
| **DevOps & stack** | [`../devops/DEVOPS.md`](../devops/DEVOPS.md) |
| **Database schema** | [`../database/DATABASE.md`](../database/DATABASE.md) |
| **Android Studio / mobile** | [`../mobile/ANDROID_STUDIO.md`](../mobile/ANDROID_STUDIO.md) |
| **Security** | [`../security/SECURITY.md`](../security/SECURITY.md) |

## PDF folder files

| File | Audience | Contents |
|------|----------|----------|
| `01_DEVOPS_INSTALLATION.md` | DevOps | → links to `devops/DEVOPS.md` |
| `02_RUN_DEMO_SERVER.md` | DevOps / Dev | Gateway 8090, Swagger, deploy scripts |
| `03_APIGEE_CONNECTION.md` | Apigee team | Proxies, JWT, chat APIs |
| `04_TESTING_GUIDE.md` | QA | Swagger, auth, chat, mobile checklist |
| `05_ANDROID_STUDIO_MOBILE.md` | Mobile devs | → links to `mobile/ANDROID_STUDIO.md` |

## API documentation

| Doc | Purpose |
|-----|---------|
| [`../api/API_OVERVIEW.md`](../api/API_OVERVIEW.md) | All endpoints + Swagger links |
| [`../api/CHAT_API.md`](../api/CHAT_API.md) | Chat API |

## Generate PDFs

```bash
cd docs/deployment/pdf
chmod +x generate-pdfs.sh
./generate-pdfs.sh
```

## Deploy & verify (from repo root)

```bash
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
./scripts/verify-localhost.sh
```

---

*Orange — my boss app*
