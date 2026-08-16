# my boss app — Testing Guide

**Audience:** QA, developers, DevOps  
**Covers:** Automated smoke tests, Swagger, auth, chat, mobile checklist

---

## 1. Smoke checks

```bash
cd myboss-platform
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
curl http://127.0.0.1:3001/api/v1/push/status
```

Do **not** run long MySQL login poll loops as part of testing — that can take the shared DB down.
---

## 2. Swagger UI (interactive API docs)

### Local (single API)

| | URL |
|---|---|
| Health | http://127.0.0.1:3001/api/v1/health |
| Swagger | http://127.0.0.1:3001/docs |
| Push status | http://127.0.0.1:3001/api/v1/push/status |

Squad join / invite / admin: [`../api/SQUADS.md`](../api/SQUADS.md). Orange SSO + Maxit curls: [`ORANGE_OTP_SETUP.md`](ORANGE_OTP_SETUP.md).

### Apigee (demo)

| Service | URL |
|---------|-----|
| Auth | https://api-demo.orange.com/auth/api/v1/docs |
| Config (+ Chat) | https://api-demo.orange.com/config/api/v1/docs |
| Squad | https://api-demo.orange.com/squad/api/v1/docs |

To test JWT endpoints in Swagger: **Authorize** → `Bearer {accessToken}`.

---

## 3. Backend health

```bash
# Direct ports
curl http://127.0.0.1:3001/api/v1/health
curl http://127.0.0.1:3001/api/v1/push/status

# Through Apigee
curl https://api-demo.orange.com/auth/api/v1/health
```

---

## 4. Auth flow (employee)

Use direct port `:3001` locally, or replace base with `https://api-demo.orange.com/auth/api/v1` on Apigee.

```bash
# Step 1 — Sign in
curl -X POST http://127.0.0.1:3001/api/v1/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}'

# Response includes sessionId and demoOtpCode (demo mode)

# Step 2 — Verify OTP (endpoint is verify-2fa)
curl -X POST http://127.0.0.1:3001/api/v1/auth/verify-2fa \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"<SESSION_ID>","code":"<OTP>"}'
```

Expected: `accessToken`, `refreshToken`, `user`.

**Orange error format** on failure:

```json
{ "code": 41, "reason": "Invalid credentials", "message": "..." }
```

---

## 5. Chat API test (native squad messaging)

Full reference: [`../api/CHAT_API.md`](../api/CHAT_API.md)

```bash
# Public
curl http://127.0.0.1:3001/api/v1/chat/config
curl http://127.0.0.1:3001/api/v1/chat/health

# JWT required
curl http://127.0.0.1:3001/api/v1/chat/visitor \
  -H "Authorization: Bearer <ACCESS_TOKEN>"

# Send message
curl -X POST http://127.0.0.1:3001/api/v1/chat/messages \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"recipientId":"1","text":"QA test message"}'
```

**Mobile chat rules:**
- User must be in a **squad** (`demo@orange.com` ✓, `omar.t@orange.com` ✗)
- Contacts = squad members only

---

## 6. Admin flow

| Mode | URL | Login |
|------|-----|-------|
| Vite dev (local APIs) | http://127.0.0.1:5173 | `admin@orange.com` / `admin123` → OTP |
| Docker (Apigee APIs) | http://127.0.0.1:8081 | same |

1. Start backend: `cd myboss-platform && docker compose up -d --build`
2. For local dev: `cd ../myboss-admin && npm run dev`
3. Verify V2 console: black sidebar, **Overview** landing page
4. Test: Squads table, Unregistered assign, Destinations save

---

## 7. Mobile app manual test

| Step | Action | Expected |
|------|--------|----------|
| 0 | Restart API / use seed users in DB | Fresh squads; users must accept T&C |
| 1 | Sign in `demo@orange.com` | OTP → **terms popup** → home |
| 2 | Toggle EN / AR | Labels change |
| 3 | Tap **Live Chat** FAB | Squad contact picker |
| 4 | Select squad member, send message | Message appears; peer can reply |
| 5 | Sign in `omar.t@orange.com` | Terms → squad hub; no-squad gating |
| 6 | Sign in `nisreen.a@orange.com` | Leader view; remove member |
| 7 | Join squad → browse list | All squads; filter by governorate |
| 8 | Reports tab (omar) | Locked panel |
| 9 | Gallery tab | Upload locked without squad |
| 10 | Profile → Log out | Returns to sign-in |
| 11 | Home online → airplane mode → open a service | Form opens from cache (questions visible) |
| 12 | Fill answers → Leave | Draft saved on device |
| 13 | Reopen same service offline | Answers restored |
| 14 | Finish + submit offline, then go online | Draft queued, then auto-submitted on Home |

Offline survey details: [`../mobile/OFFLINE_SURVEYS.md`](../mobile/OFFLINE_SURVEYS.md).

**Run mobile against Apigee:**

```bash
cd myboss-mobile
fvm flutter run \
  --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com \
  --dart-define=ENV=demo \
  --dart-define=DEMO_MODE=true
```

**Run mobile against local Docker (same Wi‑Fi / emulator):**

```bash
# Emulator
fvm flutter run \
  --dart-define=ENV=development \
  --dart-define=API_HOST=10.0.2.2 \
  --dart-define=DEMO_MODE=false

# Physical device (replace with your PC LAN IP)
fvm flutter run \
  --dart-define=ENV=development \
  --dart-define=API_HOST=192.168.x.x \
  --dart-define=DEMO_MODE=false
```

Commands: `myboss-mobile/README.md`.

---

## 8. Backend unit tests

```bash
cd myboss-backend
npm run test:auth
npm run test:user
npm run test:config
npm run test:squad
npm run test:survey
```

---

## 9. Test checklist

- [ ] Single API health OK (`curl http://127.0.0.1:3001/api/v1/health`)
- [ ] Swagger UI loads at `http://127.0.0.1:3001/docs`
- [ ] Employee sign-in + verify-2fa works (OTP emailed via Orange)
- [ ] JWT required on squad/user/chat (401 without token)
- [ ] Orange error envelope on 401
- [ ] Squad create/join works (JWT-derived user)
- [ ] Pending invites reserve seats (1-member squad: max 4 invites)
- [ ] Cancel invite frees a seat; joining deletes the user’s other requests
- [ ] Admin: rename, make leader, add unassigned, remove, delete, Invitations cancel
- [ ] Chat send + poll between squad members
- [ ] Survey submit + catalog works
- [ ] Mobile: Home online caches services; offline open + draft + submit-when-online ([`../mobile/OFFLINE_SURVEYS.md`](../mobile/OFFLINE_SURVEYS.md))
- [ ] Admin login + V2 nav loads
- [ ] Mobile EN/AR + logout + session redirect
- [ ] Apigee paths (`verify-mobile-api.sh --apigee`)

---

*Orange — my boss app — QA*
