# Apigee vs nginx — client API gateway

**Status:** nginx API gateway **removed**. Clients use **Orange Apigee** only.

---

## Summary

| Layer | Clients (mobile + admin) | Local backend dev |
|-------|--------------------------|-------------------|
| **API gateway** | **Orange Apigee** | Direct ports `:3001–3006` |
| **Demo API base** | `https://api-demo.orange.com` | `http://127.0.0.1:3001/api/v1`, … |
| **Production API base** | `https://api.orange.com` | — |

There is **no nginx** configuration in this project for API routing.

---

## Architecture

```
Mobile app / Admin SPA
        │
        ▼
Orange Apigee
        ├── /auth/api/v1/**
        ├── /user/api/v1/**
        ├── /config/api/v1/**
        ├── /squad/api/v1/**
        ├── /survey/api/v1/**
        └── /notification/api/v1/**
```

Local Docker exposes the same microservices on ports **3001–3006** for backend development. Client apps call Apigee (deployed) or direct ports (local `npm run dev` / `ENV=development`).

---

## Client configuration

| App | Build / run |
|-----|-------------|
| **Admin** | `npm run build:apigee` or `npm run dev` (localhost ports) |
| **Mobile** | `./build-apigee-android.sh` or `--dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com` |

Full URL table: [`../deployment/APIGEE_CLIENT_URLS.md`](../deployment/APIGEE_CLIENT_URLS.md)

---

## Admin Docker note

The admin container still uses nginx **only to serve static HTML/JS** (port 8081). It does **not** proxy API traffic — the SPA calls Apigee directly.

---

*Orange — my boss app*
