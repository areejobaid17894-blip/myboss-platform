# Notifications — production strategy

## Current state (demo)

| Layer | Implementation |
|-------|----------------|
| Source of truth | `survey-service` — `POST /notifications`, MariaDB target (`myboss`) |
| Employee delivery | **In-app only** — Home unread banner + Gallery announcement cards |
| Admin compose | Admin portal → `POST /notifications` |
| Employee uploads | `POST /gallery` (`source=employee`) → admin Photos |
| Persistence | JSON file + in-memory (demo) |

**No Firebase, FCM, or APNs is wired in the demo.** Users only see notifications when the app is opened.

Unified model: [`GALLERY_NOTIFICATIONS.md`](./GALLERY_NOTIFICATIONS.md)

---

## Production target architecture

```
Admin portal
    POST /notifications
         ↓
survey-service (MariaDB `myboss`: notifications + gallery_items)
         ↓
push-worker (new job / Lambda / sidecar)
         ↓
FCM (Android)  +  APNs (iOS)
         ↓
Employee device (lock screen) + in-app gallery/inbox (already built)
```

Keep **`POST /notifications`** as the single admin API. Add push delivery as a worker that reads new notifications and sends device tokens.

---

## Provider options

| Option | Pros | Cons | Cost at ~1,500 users/day |
|--------|------|------|---------------------------|
| **FCM + APNs direct** | No vendor lock-in; standard | You manage certs/tokens | **~$0** (both free) |
| **Firebase Cloud Messaging** | Easiest Flutter integration (`firebase_messaging`) | Google dependency | **~$0** on Spark for push-only |
| **AWS SNS** | Enterprise-friendly if stack is AWS | Extra AWS setup | **~$0.07/month** at ~135k msgs |
| **Azure Notification Hubs** | Good if stack is Azure | Extra Azure setup | Low at this scale |
| **OneSignal** | Fast setup, dashboard | Third-party | Free tier often sufficient |
| **In-app only (no push)** | Already built | No lock-screen alerts | **$0** — weak for field use |

**Recommendation:** Use **survey-service + in-app feed** (already done) plus **FCM + APNs** for OS push. Choose Firebase SDK vs direct HTTP based on Orange cloud policy.

---

## Scale: 1,500 users per day

| Scenario | Messages/day | Verdict |
|----------|--------------|---------|
| 1 notif × 1,500 users | 1,500 | Trivial |
| 5 notifs × 1,500 users | 7,500 | Trivial |
| 30-day event, 3/day | ~135,000/month | Well within free tiers |

FCM and APNs handle millions of messages per day. Bottleneck would be backend/DB design, not the push provider.

---

## Cost summary

| Item | Typical cost |
|------|--------------|
| FCM / APNs message delivery | **Free** |
| Push worker compute | Negligible (small container or Lambda) |
| MariaDB (notifications table) | Part of shared `myboss` database |
| Apple Developer Program | ~$99/year (App Store) |
| Google Play | ~$25 one-time (if public store) |

**Expected push infrastructure cost at 1,500 users/day: ~$0/month** excluding app-store fees and existing server hosting.

---

## Implementation checklist (production)

- [ ] `device_tokens` table (user_id, platform, token, updated_at)
- [ ] Mobile: register token on login (`firebase_messaging` or native)
- [ ] Push worker: on `POST /notifications`, resolve audience server-side, fan-out to tokens
- [ ] Persist notifications + gallery_items in MariaDB (replace JSON demo files)
- [ ] Retain in-app gallery/inbox as fallback when push is denied or app is foregrounded
- [ ] Orange sign-off on provider (Firebase vs AWS SNS vs direct FCM/APNs)

---

## Related docs

- [`GALLERY_NOTIFICATIONS.md`](./GALLERY_NOTIFICATIONS.md) — unified feed design
- [`DATA_MODEL.md`](./DATA_MODEL.md) — `notifications` + `gallery_items` schema
- [`ADMIN_JOURNEY_COVERAGE.md`](../ADMIN_JOURNEY_COVERAGE.md) — admin Notifications + Photos
- [`API_OVERVIEW.md`](../api/API_OVERVIEW.md) — REST endpoints
