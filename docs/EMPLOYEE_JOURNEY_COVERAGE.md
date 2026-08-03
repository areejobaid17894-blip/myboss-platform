# Employee journey coverage matrix

Maps **HTML mockup** (`the_boss_app.html`), **journey PDF** (Rev 1.0 July 2026), and **implemented app** (Flutter mobile + backend).

Legend: ✅ Done · 🟡 Partial · ❌ Not yet · 🔒 Gated (no-squad)

## Access & auth

| Screen / requirement | HTML | PDF | App | Notes |
|---------------------|------|-----|-----|-------|
| Sign in (email only) | scr-login | Screen #1 | ✅ | `@orange.com` domain check |
| Not eligible error | — | Screen #1 | ✅ | `AUTH_NOT_ELIGIBLE` |
| OTP 6-digit, 10 min | scr-otp | Screen #2 | ✅ | `verify-2fa`, resend |
| Terms & conditions (blocking) | — | — | ✅ | After OTP; also on cold start via `/onboarding/terms` |
| OTP brute-force limit | — | — | ✅ | 5 attempts → session invalidated |
| Demo OTP auto-fill | scr-otp | — | ✅ | `DEMO_MODE` + `demoOtpCode` |

## Onboarding

| Screen | HTML | PDF | App | Notes |
|--------|------|-----|-----|-------|
| Vest size (step 1) | scr-vest | Screen #3 | ✅ | Chip rows, info card |
| Building + governorate auto | scr-building | Screen #4 | ✅ | Gov read-only |
| Travel toggle + prefs | scr-building | Screen #4 | ✅ | Optional governorates |
| → Squad hub after onboarding | scr-squadhub | Screen #5 | ✅ | Skips vest/building if already in profile |

## Squad formation

| Screen | HTML | PDF | App | Notes |
|--------|------|-----|-----|-------|
| Squad hub + progress bar | scr-squadhub | Screen #5 | ✅ | Create disabled at cap |
| Create squad | scr-create | Screen #6–7 | ✅ | Name, badge, leader hint |
| Unique name / no numbers | — | Screen #6 | ✅ | Backend `SQUAD_NAME_REGEX` |
| Join squad search | scr-join | Screen #8 | ✅ | Loads **all** squads; governorate chips + local search |
| Success celebration | scr-success | Screen #9 | ✅ | Destination card |
| Pending join request UX | — | Screen #8 | ✅ | Home + My Squad |
| Auto-cancel other requests | — | Screen #8 | ✅ | On accept |
| Squad edit time window | — | Screen #9 | ❌ | `lockedAt` entity only |

## Main app (5 tabs)

| Tab | HTML | PDF | App | Notes |
|-----|------|-----|-----|-------|
| Home — progress ring | scr-main | Screen #10 | 🟡 | Progress card, no ring yet |
| Home — rankings | scr-main | Screen #10 | 🟡 | Report card when in squad |
| Home — no squad CTA | scr-main | — | ✅ | Create/join cards |
| Reports | scr-main | Screen #13 | ✅ | Squad members only; no-squad sees locked panel |
| Gallery grid + share | scr-main | — | ✅ | Announcement cards + employee posts; upload 🔒 without squad |
| Admin announcements in gallery | — | — | ✅ | Orange Boss cards from `POST /notifications` |
| Home unread notification banner | — | — | ✅ | Links to Gallery tab |
| My Squad leader/member | scr-main | Screen #14–15 | 🟡 | Functional, UI not full HTML |
| Profile + locked chat/survey | scr-main | — | ✅ | `SquadRequiredPanel` |

## Surveys & chat

| Feature | HTML | PDF | App | Notes |
|---------|------|-----|-----|-------|
| Dynamic survey | scr-survey | Screen #11–12 | 🟡 | `SquadAccessGate` |
| Consent ID / phone rules | — | Screen #12 | 🟡 | Validators in widgets |
| Live chat | scr-chat | — | ✅ | FAB on all tabs; squad-only contacts |
| Chat 🔒 no squad | — | — | ✅ | Locked view + CTA |

## No-squad user (`omar.t@orange.com`)

| Case | Expected | App |
|------|----------|-----|
| Post-auth landing | `/squad/hub` | ✅ |
| Home tab | No-squad card, locked services | ✅ |
| Chat | Locked | ✅ |
| Gallery upload | Locked; browse OK | ✅ |
| Surveys | `SquadAccessGate` blocks | ✅ |
| Reports | Locked panel (join/create CTA) | ✅ |
| My Squad | Empty state + join/create | ✅ |

## Security (demo vs production)

| Control | Demo | Production target |
|---------|------|-------------------|
| JWT on protected APIs | ✅ | ✅ |
| `JWT_SECRET` validation (non-dev) | ✅ boot check | ✅ |
| OTP in API body | `TWO_FA_DEMO_ENABLED` only | ❌ off |
| OTP attempt limit | ✅ 5 tries | ✅ |
| Secure token storage (mobile) | ✅ Keychain/Keystore | ✅ |
| HTTPS / tunnel | Demo tunnel | Required |

## Verification commands

```bash
# Full localhost smoke (auth, squad, omar gating, chat, survey)
./infrastructure/scripts/verify-localhost.sh

# Quick (skip chat/survey)
./infrastructure/scripts/verify-localhost.sh --quick
```

## Local UI vs deployed web

| Build | URL | UI version |
|-------|-----|------------|
| Local dev | `./apps/mobile/run-local-web.sh` → `:8092` | Latest Flutter source |
| Deployed demo | `ALLOW_DEPLOY=1 ./infrastructure/scripts/deploy-mobile-web.sh` | Same as `:8092` after deploy |
| Android emulator | `fvm flutter run -d emulator-5554 …` | Latest |

Reference files: `/Users/macbookair/Downloads/the_boss_app.html`, `/Users/macbookair/Downloads/v1 Platform employee journey Rev 1.0 July 2026.pptx.pdf`
