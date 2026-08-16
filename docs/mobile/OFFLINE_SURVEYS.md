# Offline surveys (employee app)

**Audience:** Mobile, QA  
**Code:** `myboss-mobile`

Employees can open and fill cached services without internet. Closing a service saves a **draft** on the phone. When the app is online again, queued submissions are sent automatically.

The API is unchanged. Offline is **client-side only**.

---

## What is cached (online Home)

When the user opens Home **with internet**, the app stores:

| Data | Where | Used for |
|------|--------|----------|
| Survey catalog + full question schemas | `SurveySchemaCache` | Open / fill a service offline |
| Last profile + squad | `SessionOfflineStore` | Stay on Home and pass the squad gate offline |
| In-progress answers | `SurveyDraftStore` | Restore a draft |
| Finished-but-unsent responses | `SurveyDraftStore` pending queue | Submit later |

`GET /surveys/catalog` does **not** include questions. Home therefore also prefetches `GET /surveys/active/:segment` for each active service and writes those schemas to disk.

---

## Offline behaviour

1. Open the app **online** once after install (or after a survey change) and wait on Home until services appear.
2. Go offline (airplane mode).
3. Open a service from cache, fill answers.
4. Close the service → answers are saved as a draft. The leave dialog confirms this.
5. Reopen the same service offline → the draft is restored.
6. Finish + submit while offline → stored in the pending queue (`saved as draft`).
7. Open the app online → `SurveyOfflineSync.flushPending` submits the queue.

Without a prior online Home load, there is nothing to open offline.

---

## Files

| File | Role |
|------|------|
| `lib/features/survey/data/survey_schema_cache.dart` | Persist catalog + schemas |
| `lib/core/session/session_offline_store.dart` | Persist last profile + squad |
| `lib/features/survey/data/survey_draft_store.dart` | Drafts + pending submit queue |
| `lib/features/survey/data/survey_offline_sync.dart` | Flush pending when back online |
| `lib/features/survey/data/repositories/survey_repository_impl.dart` | Prefetch schemas; fall back to cache |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Show cached services immediately |
| `lib/features/survey/presentation/cubit/dynamic_survey_cubit.dart` | Open from cache; `saveDraftOnClose` |

---

## QA

| Step | Expected |
|------|----------|
| Install APK, open Home **online** | Services list loads; schemas cached |
| Airplane mode → open a service | Form opens with questions (not a network error) |
| Answer some questions → Leave | Draft saved on device |
| Reopen the same service offline | Answers restored |
| Finish + submit offline | “Saved offline” / draft queued |
| Wi‑Fi on → open Home | Pending draft submits; progress updates |

Login, OTP, chat, gallery, and admin still need internet.

---

*Orange — my boss app — Mobile*
