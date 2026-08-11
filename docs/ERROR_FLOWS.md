# Error flows & messages — my boss app

Every API error returns the Orange envelope:

```json
{ "code": 41, "reason": "Invalid credentials", "message": "...", "infoURL": "https://api.orange.com/errors/41" }
```

**Source files:**
- Backend codes: `myboss-backend/libs/common/src/errors/app-error-codes.ts`
- Orange mapping: `myboss-backend/libs/common/src/errors/orange-error-codes.ts`
- Backend messages (en/ar): `myboss-backend/libs/common/src/errors/error-messages.ts`
- Admin UI: `myboss-admin/src/api/errors.ts` + `src/i18n/en.ts`
- Mobile UI: `myboss-mobile/lib/core/error/failure_message_mapper.dart` + `l10n/app_en.arb`

---

## How to read this doc

| Column | Meaning |
|--------|---------|
| **Step** | Where the user is in the journey |
| **What happens** | Condition that triggers the error |
| **Code** | Internal `AppErrorCode` |
| **Orange / HTTP** | Governance code and HTTP status |
| **User sees** | Message shown in admin or mobile (English) |

---

# A. Authentication flows

## A1. Employee sign-in (mobile / web)

**Flow:** Enter email → `POST /auth/sign-in` → OTP screen

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Enter email | Email is not `@orange.com` | `AUTH_INVALID_DOMAIN` | 22 / 400 | Please use your @orange.com work email address. |
| Enter email | Email not in eligible participants list | `AUTH_NOT_ELIGIBLE` | 52 / 403 | You are not eligible to participate. |
| Enter email | Invalid email format (server validation) | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid. Please review your input. |
| Enter email | Invalid email format (client) | — | — | Submit button disabled (no message) |
| Send OTP | Orange email API fails (production OTP) | `AUTH_OTP_SEND_FAILED` | 5 / 502 | Something went wrong. Please try again. |
| Any step | No network / server down | — | — | Network error. Please check your connection. |

**Backend:** `auth-service/src/modules/auth/auth.service.ts` → `initiateOtpFlow`

---

## A2. Admin sign-in (admin portal)

**Flow:** Enter email + password → `POST /auth/admin-sign-in` → OTP screen

| Step | What happens | Code | Orange / HTTP | User sees (admin) |
|------|--------------|------|---------------|-------------------|
| Submit login | Wrong email or password | `AUTH_INVALID_CREDENTIALS` | 41 / 401 | Invalid email or password. |
| Submit login | Invalid email/password format | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid. Please review your input. |
| Send OTP | Email service unavailable | `AUTH_OTP_SEND_FAILED` | 5 / 502 | Cannot reach the backend… or generic error |
| After response | Response missing sessionId | — | — | Something went wrong. Please try again. |
| After response | Token returned without 2FA step | — | — | Admin 2FA is required. Restart auth-service (port 3001) and try again. |
| Any step | No network | — | — | Network error. Please check your connection. |

**Backend:** `auth.service.ts` → `adminSignIn`  
**Admin UI:** `src/pages/LoginPage.tsx`

---

## A3. Verify OTP (admin + mobile)

**Flow:** Enter 6-digit code → `POST /auth/verify-2fa` → logged in

| Step | What happens | Code | Orange / HTTP | User sees |
|------|--------------|------|---------------|-----------|
| Submit OTP | Wrong code or max attempts exceeded | `AUTH_INVALID_OTP` | 41 / 401 | Invalid or expired verification code. |
| Submit OTP | Session lost after verify | `AUTH_SESSION_INVALID` | 42 / 401 | Admin: Your session expired… / Mobile: Your session is invalid… |
| Submit OTP | Code not 6 digits (server) | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Open OTP page | sessionId missing (client) | — | — | Mobile: Your session expired. Please sign in again. |

**Backend:** `auth.service.ts` → `verifyTwoFactor`

---

## A4. Resend OTP

**Flow:** Tap resend → `POST /auth/resend-otp`

| Step | What happens | Code | Orange / HTTP | User sees |
|------|--------------|------|---------------|-----------|
| Resend | OTP session expired or deleted | `AUTH_SESSION_EXPIRED` | 42 / 401 | Your session expired. Please sign in again. |
| Resend | Invalid sessionId | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |

**Backend:** `auth.service.ts` → `resendOtp`

---

## A5. Refresh token (silent session renew)

**Flow:** App calls `POST /auth/refresh` when access token expires

| Step | What happens | Code | Orange / HTTP | User sees |
|------|--------------|------|---------------|-----------|
| Refresh | Refresh token invalid or expired | `AUTH_INVALID_REFRESH_TOKEN` | 42 / 401 | Session expired message; mobile redirects to sign-in |
| Refresh | User no longer exists | `AUTH_INVALID_REFRESH_TOKEN` | 42 / 401 | Same as above |

**Backend:** `auth.service.ts` → `refreshToken`  
**Mobile:** `lib/core/network/dio_client.dart` — silent redirect, no toast

---

## A6. Add employee (admin)

**Flow:** Admin adds employee → `POST /auth/eligible-participants`

| Step | What happens | Code | Orange / HTTP | User sees (admin) |
|------|--------------|------|---------------|-------------------|
| Submit form | Email not `@orange.com` | `AUTH_INVALID_DOMAIN` | 22 / 400 | Please use your @orange.com work email address. |
| Submit form | Invalid email (server) | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Submit form | Missing required fields (client) | — | — | Browser validation on form |

**Backend:** `auth.service.ts` → `addEligibleParticipant`  
**Admin UI:** `src/components/admin/AddEmployeeCard.tsx`

---

# B. Session & access guards

Apply to **any protected API** when JWT or role checks fail.

| Step | What happens | Code | Orange / HTTP | User sees |
|------|--------------|------|---------------|-----------|
| Call API without token | Missing `Authorization` header | `UNAUTHORIZED` | 40 / 401 | Authentication required. Please sign in again. |
| Call API with bad token | JWT invalid or expired | `AUTH_SESSION_INVALID` | 42 / 401 | Session invalid / expired; mobile ends session |
| Admin-only route | User is not admin | `FORBIDDEN` | 50 / 403 | You are not allowed to perform this action. |
| Employee-only route | User is not employee | `FORBIDDEN` | 50 / 403 | You are not allowed to perform this action. |
| Access another user's data | Not self and not admin | `FORBIDDEN` | 50 / 403 | You are not allowed to perform this action. |
| Internal service call | Wrong `X-Internal-Service-Token` | `UNAUTHORIZED` | 40 / 401 | (service-to-service only) |

**Backend:** `libs/common/src/guards/jwt-auth.guard.ts`, `roles.guard.ts`, `auth-policy.util.ts`

---

# C. User & profile flows

## C1. Load / update profile (mobile)

**Flow:** Profile screen → `GET/PUT /users/:id/profile`

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Load profile | User ID not found | `USER_NOT_FOUND` | 60 / 404 | User not found. |
| Save profile | Max edit count reached | `USER_PROFILE_EDIT_LIMIT` | 50 / 403 | Maximum profile edits reached. |
| Save profile | Vest size change outside admin window | `USER_PROFILE_EDIT_OUTSIDE_WINDOW` | 50 / 403 | Vest size can only be changed during the scheduled edit window. |
| Save profile | Empty userId (client) | — | — | Something went wrong. Please try again. |
| Vest size field | Outside window (UI only) | — | — | Field disabled + window message |

**Backend:** `user-service/.../users.service.ts`

---

## C2. User management (admin)

**Flow:** Admin user list / create / delete

| Step | What happens | Code | Orange / HTTP | User sees (admin) |
|------|--------------|------|---------------|-------------------|
| Load users | API failure | *(mapped)* | varies | Failed to load users. |
| Create user | Duplicate email | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Get/update/delete | User not found | `USER_NOT_FOUND` | 60 / 404 | The requested item was not found. |

---

# D. Onboarding flow (mobile)

**Flow:** Terms → buildings → profile fields → complete

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Load buildings | Unknown building ID | `BUILDING_NOT_FOUND` | 60 / 404 | Building not found. |
| Load buildings | Network error | — | — | Network error… |
| Accept terms | User declines (client) | — | — | Flow blocked; stays on terms |
| Save onboarding | Invalid field values | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |

---

# E. Squad flows (mobile)

## E1. Create squad

**Flow:** Enter name → `POST /squads`

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Submit | Max squads limit reached | `SQUAD_LIMIT_REACHED` | 50 / 403 | Maximum squad limit reached. Please join an existing squad. |
| Submit | Name already taken | `SQUAD_NAME_TAKEN` | 69 / 409 | Squad name is already taken. |
| Submit | Already in a squad | `SQUAD_ALREADY_MEMBER` | 69 / 409 | You are already in a squad. |
| Submit | Invalid name format | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Submit | User-service unreachable | `BACKEND_UNAVAILABLE` | 5 / 503 | Cannot reach the backend… |
| Submit | Empty name (client) | — | — | Submit disabled |

---

## E2. Join squad

**Flow:** Pick squad → `POST /squads/:id/join-request`

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Submit | Squad not found | `SQUAD_NOT_FOUND` | 60 / 404 | Squad not found. |
| Submit | Squad is full | `SQUAD_FULL` | 50 / 403 | This squad is full. |
| Submit | Already in a squad | `SQUAD_ALREADY_MEMBER` | 69 / 409 | You are already in a squad. |
| Submit | Join request already pending | `SQUAD_JOIN_REQUEST_EXISTS` | 69 / 409 | Join request already sent. |

---

## E3. Leader actions (approve / remove / transfer / leave)

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Approve/reject request | Caller is not leader | `SQUAD_LEADER_ONLY` | 50 / 403 | Only the squad leader can perform this action. |
| Approve/reject request | Request not found | `SQUAD_JOIN_REQUEST_NOT_FOUND` | 60 / 404 | Join request not found. |
| Approve request | Squad full at accept time | `SQUAD_FULL` | 50 / 403 | This squad is full. |
| Remove member | Caller is not leader | `SQUAD_LEADER_ONLY` | 50 / 403 | Only the squad leader can perform this action. |
| Remove self as leader | Leader tries to remove self | `SQUAD_LEADER_CANNOT_REMOVE_SELF` | 50 / 403 | Transfer leadership before removing yourself. |
| Transfer leadership | Target not in squad | `SQUAD_MEMBER_NOT_FOUND` | 60 / 404 | Member not found in this squad. |
| Leave squad | Leader tries to leave | `SQUAD_LEADER_CANNOT_LEAVE` | 50 / 403 | Transfer leadership before leaving the squad. |

**Backend:** `squad-service/.../squads.service.ts`

---

## E4. Squad-gated features (survey, gallery, chat)

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Use feature without squad | No squad on profile | `SQUAD_MEMBERSHIP_REQUIRED` | 50 / 403 | Something went wrong. *(mapper gap — should show squad message)* |
| Open chat/survey/gallery | No squad (client UI) | — | — | “Join a squad first” panel (no API call) |

---

# F. Survey flows

## F1. Load & submit survey (mobile)

**Flow:** Open survey → answer questions → submit → `POST /surveys/responses`

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Load catalog | Survey not found | `SURVEY_NOT_FOUND` | 60 / 404 | Survey not found. |
| Load by segment | No active survey | `SURVEY_SEGMENT_NOT_FOUND` | 60 / 404 | No active survey for this segment. |
| Submit | User ID mismatch | `FORBIDDEN` | 50 / 403 | You are not allowed to perform this action. |
| Submit | Survey not found | `SURVEY_NOT_FOUND` | 60 / 404 | Survey not found. |
| Submit | Missing squadId | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Submit | Not in a squad | `SQUAD_MEMBERSHIP_REQUIRED` | 50 / 403 | Generic error *(mapper gap)* |
| Before submit | Required question empty (client) | — | — | Next/Submit button disabled |
| Load complete | No questions (client) | — | — | No questions available for this survey. |

---

## F2. Survey editor (admin)

**Flow:** Create/edit/delete survey schema

| Step | What happens | Code | Orange / HTTP | User sees (admin) |
|------|--------------|------|---------------|-------------------|
| Save / load / delete | API error | *(mapped)* | varies | Mapped via `getApiErrorMessage` |
| Delete | Survey not found | `SURVEY_NOT_FOUND` | 60 / 404 | The requested item was not found. |

---

# G. Gallery flow (mobile)

**Flow:** Pick photo → upload → `POST /gallery`

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Upload | User ID mismatch | `FORBIDDEN` | 50 / 403 | You are not allowed to perform this action. |
| Upload | Missing squadId | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Upload | Not in squad | `SQUAD_MEMBERSHIP_REQUIRED` | 50 / 403 | Generic error *(mapper gap)* |
| Upload | 20 photos limit (server) | `GALLERY_UPLOAD_LIMIT` | 50 / 403 | Maximum uploads reached for this employee. |
| Before upload | 20 photos limit (client) | — | — | Maximum uploads reached for this employee. |
| No squad | UI gate | — | — | Join a squad to upload photos |

---

# H. Chat flow (mobile)

**Flow:** Open chat → poll messages → send message

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Get visitor | No auth token | `UNAUTHORIZED` | 40 / 401 | Authentication required… |
| Get visitor | Invalid JWT | `AUTH_SESSION_INVALID` | 42 / 401 | Session invalid… |
| List messages | Missing peerId | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Send message | Empty text or recipient | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Send message | Message to self | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Poll / send | Network failure | — | — | Network error. Please check your connection. |
| Open chat | No squad (client) | — | — | Squad required panel |

**Backend:** `config-service/.../chat.service.ts`

---

# I. Configuration flow (admin)

**Flow:** Admin opens Configuration → edit limits → save

| Step | What happens | Code | Orange / HTTP | User sees (admin) |
|------|--------------|------|---------------|-------------------|
| Save settings | Invalid numbers in form | `VALIDATION_FAILED` | 22 / 400 | Some fields are invalid… |
| Load / save | Any API error | *(mapped)* | varies | Mapped API error message |

**Backend:** `config-service/.../app-config.service.ts`

---

# J. Notifications (admin + mobile)

## J1. Admin send notification

| Step | What happens | Code | Orange / HTTP | User sees (admin) |
|------|--------------|------|---------------|-------------------|
| Send | Empty title or body (client) | — | — | Add a title and a message first |
| Send | Non-image attachment (client) | — | — | Please choose an image file |
| Send | API failure | *(mapped)* | varies | Failed to send notification |
| Send | Not admin | `FORBIDDEN` | 50 / 403 | You are not allowed… |

## J2. Mobile notification detail

| Step | What happens | Code | Orange / HTTP | User sees (mobile) |
|------|--------------|------|---------------|-------------------|
| Open notification | ID not found | `NOT_FOUND` | 60 / 404 | This notification is no longer available. |

---

# K. Network & infrastructure errors

Apply to **any** API call when connectivity or services fail.

| Condition | Code | User sees (admin) | User sees (mobile) |
|-----------|------|-------------------|------------------|
| No HTTP response (offline, CORS, timeout) | — | Network error. Please check your connection. | Network error. Please check your connection. |
| 502 / 503 / 504 | `BACKEND_UNAVAILABLE` / internal | Cannot reach the backend. Ensure services are running and port 3001 is free. | Cannot reach the backend… |
| 404 on unknown route | `BACKEND_UNAVAILABLE` (mobile) | Cannot reach the backend… | Cannot reach the backend… |
| Unhandled server exception | `INTERNAL_ERROR` | Something went wrong. Please try again. | Something went wrong. Please try again. |
| React crash (admin) | — | Something went wrong / unexpected error — refresh page | — |

---

# L. Complete error code reference

| Code | Orange | HTTP | Backend message (en) | Used in flows |
|------|--------|------|----------------------|---------------|
| `VALIDATION_FAILED` | 22 | 400 | Some fields are invalid. Please review your input. | All DTO validation, chat, survey |
| `INTERNAL_ERROR` | 1 | 500 | Something went wrong. Please try again later. | Unhandled exceptions |
| `UNAUTHORIZED` | 40 | 401 | Authentication required. | Guards, chat |
| `FORBIDDEN` | 50 | 403 | You are not allowed to perform this action. | Roles, survey scope |
| `NOT_FOUND` | 60 | 404 | The requested resource was not found. | Notifications |
| `AUTH_INVALID_OTP` | 41 | 401 | Invalid or expired verification code. | Verify 2FA |
| `AUTH_SESSION_INVALID` | 42 | 401 | Your session is invalid. Please sign in again. | JWT guard, verify 2FA |
| `AUTH_SESSION_EXPIRED` | 42 | 401 | Your session expired. Please sign in again. | Resend OTP |
| `AUTH_INVALID_REFRESH_TOKEN` | 42 | 401 | Your session expired. Please sign in again. | Refresh token |
| `AUTH_INVALID_DOMAIN` | 22 | 400 | Please use your @orange.com work email address. | Sign-in, add employee |
| `AUTH_NOT_ELIGIBLE` | 52 | 403 | You are not eligible to participate. | Employee sign-in |
| `AUTH_INVALID_CREDENTIALS` | 41 | 401 | Invalid email or password. | Admin sign-in |
| `AUTH_OTP_SEND_FAILED` | 5 | 502 | Unable to send verification code. Please try again later. | Orange OTP (production) |
| `USER_NOT_FOUND` | 60 | 404 | User not found. | User CRUD, squad profile |
| `USER_PROFILE_EDIT_LIMIT` | 50 | 403 | Maximum profile edits reached. | Profile update |
| `USER_PROFILE_EDIT_OUTSIDE_WINDOW` | 50 | 403 | Vest size can only be changed during the scheduled edit window. | Profile update |
| `BUILDING_NOT_FOUND` | 60 | 404 | Building not found. | Onboarding |
| `SQUAD_NOT_FOUND` | 60 | 404 | Squad not found. | Squad operations |
| `SQUAD_LIMIT_REACHED` | 50 | 403 | Maximum squad limit reached… | Create squad |
| `SQUAD_NAME_TAKEN` | 69 | 409 | Squad name is already taken. | Create squad |
| `SQUAD_ALREADY_MEMBER` | 69 | 409 | You are already in a squad. | Create/join squad |
| `SQUAD_FULL` | 50 | 403 | This squad is full. | Join/approve |
| `SQUAD_JOIN_REQUEST_EXISTS` | 69 | 409 | Join request already sent. | Join squad |
| `SQUAD_JOIN_REQUEST_NOT_FOUND` | 60 | 404 | Join request not found. | Leader approve/reject |
| `SQUAD_LEADER_ONLY` | 50 | 403 | Only the squad leader can perform this action. | Leader actions |
| `SQUAD_LEADER_CANNOT_LEAVE` | 50 | 403 | Transfer leadership before leaving the squad. | Leave squad |
| `SQUAD_LEADER_CANNOT_REMOVE_SELF` | 50 | 403 | Transfer leadership before removing yourself. | Remove member |
| `SQUAD_MEMBER_NOT_FOUND` | 60 | 404 | Member not found in this squad. | Transfer leadership |
| `SURVEY_NOT_FOUND` | 60 | 404 | Survey not found. | Survey load/submit |
| `SURVEY_SEGMENT_NOT_FOUND` | 60 | 404 | No active survey for this segment. | Survey catalog |
| `GALLERY_UPLOAD_LIMIT` | 50 | 403 | Maximum uploads reached for this employee. | Gallery upload |
| `SQUAD_MEMBERSHIP_REQUIRED` | 50 | 403 | You must join a squad before using this feature. | Survey, gallery |
| `BACKEND_UNAVAILABLE` | 5 | 503 | Cannot reach the backend… | Squad user-service client |

**Defined but not thrown today:** `CONFIG_NOT_FOUND`

---

# M. Known gaps (mobile mapper)

These backend codes exist but mobile may show a **generic** message until mapper is updated:

- `SQUAD_MEMBERSHIP_REQUIRED`
- `AUTH_OTP_SEND_FAILED`
- `AUTH_INVALID_CREDENTIALS` (admin-only flow)

---

*Orange — my boss app*
