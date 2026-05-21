# LuxiHub — Full System Architecture Reference

> **Purpose:** Complete technical reference for anyone building the **LuxiHub User (Client) App** or extending the existing **Handyman App**. Read this before touching any code.

---

## 1. Platform Overview

LuxiHub is a two-sided marketplace for home services:

| App | Role | Status |
|---|---|---|
| `luxihub_handyman` | Service provider (tradesperson) | **Built — this repo** |
| `luxihub_user` (to build) | Client who posts jobs | Not started |

Both apps share the **same Supabase project** (same DB, Auth, Storage, Edge Functions).

---

## 2. Technology Stack

| Layer | Choice |
|---|---|
| Mobile framework | Flutter (Dart) |
| State management | BLoC (`flutter_bloc ^9.x`, `bloc ^9.x`) |
| Navigation | GoRouter (`go_router ^17.x`) |
| Backend | Supabase (Auth + PostgreSQL + Storage + Realtime + Edge Functions) |
| Payments | Stripe Connect (Express accounts, transfers) |
| DI / Service Locator | GetIt (`get_it ^8.x`) |
| HTTP client | Dio (`dio ^5.x`) — used for Google Geocoding API |
| Maps | `google_maps_flutter ^2.17` with `google_maps_flutter_android ^2.19` |
| Image picking | `image_picker ^1.x` |
| Responsive layout | `flutter_screenutil ^5.x` (design size: 390 × 844) |

---

## 3. Flutter Project Architecture

Strict **Clean Architecture** per feature:

```
lib/
├── core/
│   ├── config/
│   │   ├── supabase_config.dart       ← Supabase URL + anon key
│   │   └── maps_config.dart           ← Google Maps API key
│   ├── di/
│   │   └── service_locator.dart       ← GetIt registrations (all features)
│   ├── error/
│   │   ├── exceptions.dart            ← ServerException
│   │   └── failures.dart              ← ServerFailure, extends Failure
│   ├── router/
│   │   ├── app_router.dart            ← GoRouter config + auth redirect
│   │   └── app_routes.dart            ← RouteModel constants (name + path)
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── usecases/
│   │   └── usecase.dart               ← abstract UseCase<Type, Params> base
│   └── utils/
│       └── app_date_utils.dart        ← DOB formatting (ISO ↔ "15 Jan 1990")
│
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/           ← All Supabase SDK calls live here
        │   ├── models/                ← JSON-serialisable, has toEntity()
        │   └── repositories/          ← Implements domain interface
        ├── domain/
        │   ├── entities/              ← Pure Dart, no dependencies, Equatable
        │   ├── repositories/          ← Abstract interface (Either<Failure, T>)
        │   └── usecases/              ← One class per operation
        └── presentation/
            ├── bloc/                  ← Event → State, calls use cases
            ├── pages/
            └── widgets/
```

### Error handling convention

Every repository method returns `Either<Failure, T>` (dartz). Datasources throw `ServerException`; repositories catch it and return `Left(ServerFailure(...))`. BLoC folds the Either and emits the appropriate error state.

### Dependency injection

All registrations are in `lib/core/di/service_locator.dart`.
- `SupabaseClient` is a lazy singleton.
- Datasources, repositories, and use cases are lazy singletons.
- BLoC instances are **factories** (new instance per screen).

---

## 4. Database Schema

### `auth.users` (Supabase managed)
Standard Supabase Auth table. `id` (UUID) is the foreign key used across all tables.

---

### `profiles`
One row per user (handyman **and** client share this table).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK, references `auth.users.id` |
| `name` | `text` | Display name |
| `phone` | `text` | |
| `email` | `text` | |
| `dob` | `date` | ISO format `YYYY-MM-DD` |
| `contract_type` | `text` | `hourly` · `contractual` · `both` |
| `hourly_rate` | `numeric` | RM per hour |
| `service_area` | `text` | Human-readable city/suburb label |
| `service_lat` | `float8` | Map pin latitude |
| `service_lng` | `float8` | Map pin longitude |
| `service_radius_km` | `int` | Service coverage radius |
| `avatar_path` | `text` | Public URL from `avatars` storage bucket |
| `is_online` | `bool` | Default `false` |
| `is_kyc_verified` | `bool` | Default `false` — set by admin after KYC review |
| `stripe_account_id` | `text` | Stripe Express account ID (handyman only) |
| `stripe_payouts_enabled` | `bool` | Synced from Stripe via `stripe-connect-return` edge function |
| `created_at` | `timestamptz` | Default `now()` |

---

### `skills`
Many-to-one with `profiles`.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `profile_id` | `uuid` | FK → `profiles.id` |
| `name` | `text` | e.g. `Plumbing`, `Carpentry` |

Skills are always replaced in full on profile update: delete all for `profile_id`, then re-insert.

---

### `job_requests`
Core entity. Posted by clients, accepted by handymen.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `client_id` | `uuid` | FK → `auth.users.id` |
| `provider_id` | `uuid` | FK → `profiles.id`, null until accepted |
| `category` | `text` | Job category (e.g. `Plumbing`) |
| `description` | `text` | Problem details |
| `status` | `text` | `pending` · `accepted` · `rejected` · `completed` |
| `amount` | `numeric` | Agreed/invoiced amount (used for earnings) |
| `client_lat` | `float8` | Client location latitude |
| `client_lng` | `float8` | Client location longitude |
| `posted_at` | `timestamptz` | Default `now()` |
| `completed_at` | `timestamptz` | Set when status → `completed` |

---

### `job_attachments`
Photos the client uploads with a job request.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `job_request_id` | `uuid` | FK → `job_requests.id` |
| `storage_path` | `text` | Path in `job-attachments` storage bucket |
| `uploaded_at` | `timestamptz` | Default `now()` |

---

### `conversations`
One conversation per accepted job. Denormalised for inbox performance.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `job_request_id` | `uuid` | FK → `job_requests.id` |
| `provider_id` | `uuid` | FK → `profiles.id` |
| `client_id` | `uuid` | FK → `auth.users.id` |
| `last_message` | `text` | Denormalised — update on every new message |
| `last_message_at` | `timestamptz` | |
| `unread_count` | `int` | Default `0` — increment on new message, reset on read |

---

### `messages`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `conversation_id` | `uuid` | FK → `conversations.id` |
| `sender_id` | `uuid` | FK → `auth.users.id` |
| `text` | `text` | |
| `created_at` | `timestamptz` | Default `now()` |

---

### `wallet`
One row per handyman.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK, references `profiles.id` (1-to-1) |
| `balance` | `numeric` | Current available balance (RM) |
| `updated_at` | `timestamptz` | |

**Important:** Never upsert with a hardcoded `balance: 0` — use select + conditional insert to avoid overwriting real balances.

---

### `withdrawals`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `profile_id` | `uuid` | FK → `profiles.id` |
| `amount` | `numeric` | Amount requested |
| `bank_name` | `text` | From Stripe external account (display only) |
| `account_last4` | `text` | From Stripe external account (display only) |
| `status` | `text` | `pending` · `completed` · `rejected` |
| `stripe_transfer_id` | `text` | Set after `process-withdrawal` runs — prevents double-pay |
| `created_at` | `timestamptz` | Default `now()` |

---

### `kyc_documents`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | PK |
| `profile_id` | `uuid` | FK → `profiles.id` |
| `type` | `text` | `National ID` · `Passport` · `Driving Licence` |
| `front_path` | `text` | Storage path in `kyc-documents` bucket |
| `back_path` | `text` | Storage path |
| `selfie_path` | `text` | Storage path |
| `status` | `text` | `pending` · `approved` · `rejected` |
| `submitted_at` | `timestamptz` | Default `now()` |

---

## 5. Database Triggers

### `trg_deduct_on_withdrawal`
**Table:** `withdrawals` · **Event:** `AFTER INSERT`

Deducts `NEW.amount` from `wallet.balance` where `wallet.id = NEW.profile_id` immediately when a withdrawal row is inserted. Balance goes negative if insufficient funds — add a DB-level check constraint if you want to prevent overdraft.

### `trg_refund_on_rejection`
**Table:** `withdrawals` · **Event:** `AFTER UPDATE`

When `OLD.status <> 'rejected' AND NEW.status = 'rejected'`, adds `NEW.amount` back to `wallet.balance`. This is the automatic refund mechanism when an admin rejects a withdrawal.

---

## 6. Storage Buckets

| Bucket | Access Policy | Used For |
|---|---|---|
| `avatars` | **Public read**, owner write/update/delete | Profile photos — URL stored in `profiles.avatar_path` |
| `kyc-documents` | **Owner only** | KYC front/back/selfie — private, never public |
| `job-attachments` | Authenticated read, owner write | Photos attached to job requests by clients |

**Avatar upload path:** `{userId}/avatar.{ext}` — always upserted, so only one file per user.

**KYC RLS policies** (storage.objects):
```sql
INSERT: bucket_id = 'kyc-documents' AND (storage.foldername(name))[1] = auth.uid()::text
SELECT: bucket_id = 'kyc-documents' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Avatar RLS policies** (storage.objects):
```sql
INSERT/UPDATE/DELETE: bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text
SELECT: bucket_id = 'avatars' (public)
```

---

## 7. Supabase Edge Functions

All functions are in `supabase/functions/`. Deployed with `supabase functions deploy <name>`.

### `create-connect-account`
**Trigger:** Handyman taps "Connect Stripe" in wallet page.
**Flow:**
1. Verifies caller is authenticated (JWT check via anon client).
2. If handyman has no `stripe_account_id`, creates a Stripe Express account and saves to `profiles`.
3. If account exists, syncs `payouts_enabled` from Stripe into `profiles.stripe_payouts_enabled`.
4. Creates a Stripe Account Link (onboarding URL) with:
   - `refresh_url` → `stripe-connect-return` edge function
   - `return_url` → `stripe-connect-return?pid={userId}`
5. Returns `{ url: "https://connect.stripe.com/..." }`.
6. Flutter opens URL in external browser via `url_launcher`.

---

### `stripe-connect-return`
**Trigger:** Browser returns from Stripe onboarding (redirect URL).
**Flow:**
1. Reads `pid` query param (profile ID).
2. Retrieves Stripe account and syncs `payouts_enabled` → `profiles.stripe_payouts_enabled`.
3. Serves an HTML page that deep-links back to the app via `luxihub://stripe-return` (iOS) or Intent URI (Android).

**Deep link scheme:** `luxihub` · **Host:** `stripe-return`

---

### `process-withdrawal`
**Trigger:** Admin panel calls this to approve and pay out a withdrawal.
**Flow:**
1. Takes `{ withdrawal_id }` in request body (no auth check — admin-only, should be called server-side).
2. Fetches withdrawal + `profiles.stripe_account_id` via join.
3. If `stripe_transfer_id` already exists → idempotent return (prevents double-pay).
4. Creates `stripe.transfers.create({ amount, currency: 'eur', destination: stripeAccountId })`.
5. Saves `transfer.id` to `withdrawals.stripe_transfer_id`.
6. Returns `{ transfer_id }`.

---

### `get-stripe-bank-details`
**Trigger:** Withdrawal bottom sheet opening (Flutter calls this).
**Flow:**
1. Verifies caller is authenticated (JWT check).
2. Takes `{ stripe_account_id }` from request body.
3. Calls `stripe.accounts.listExternalAccounts(accountId, { object: 'bank_account', limit: 1 })`.
4. Returns `{ bank_name, account_last4 }` — displayed as read-only in the withdrawal sheet.

---

## 8. Realtime Subscriptions

| Table | Method | Filter | Used In | Purpose |
|---|---|---|---|---|
| `job_requests` | `.stream()` | `status = pending` | `DashboardPage` | Live new job alerts |
| `messages` | `.stream()` | `conversation_id = <id>` | `ChatPage` | Live message feed |
| `conversations` | (planned) | `provider_id = <uid>` | `InboxPage` | Live unread count |

All Realtime streams are managed in BLoC handlers via `emit.forEach(stream, ...)`.

---

## 9. Authentication Flow

### Phone OTP (primary)
```
User enters phone
  → SendPhoneOtp use case
  → supabase.auth.signInWithOtp(phone: ...)
  → OTP sent via SMS
User enters OTP
  → VerifyPhoneOtp use case
  → supabase.auth.verifyOTP(type: OtpType.sms, phone: ..., token: ...)
  → Session created → AuthAuthenticated state
  → Router redirects to dashboard
```

### Email + Password (fallback)
```
supabase.auth.signUpWithPassword / signInWithPassword
```

### Auth State
`AuthBloc` monitors `supabase.auth.onAuthStateChange` stream. States:
- `AuthInitial` → checking session
- `AuthLoading`
- `AuthAuthenticated(AppUser)` → logged in
- `AuthUnauthenticated` → logged out → router sends to `/login`
- `AuthPendingApproval` → account exists but KYC not approved
- `AuthOtpSent` → waiting for user to enter OTP

### Credential Update (phone/email)
Done via OTP confirmation in edit profile:
```
supabase.auth.updateUser(UserAttributes(phone/email: newValue))
  → OTP sent to new number/email
supabase.auth.verifyOTP(type: OtpType.phoneChange / emailChange, ...)
  → Auth record updated
  → profiles table also updated manually for cache consistency
```

---

## 10. Feature Flows (Handyman App)

### Profile
- **Fetch:** `profiles` + `skills` joined (`select('*, skills(name)')`)
- **Update:** UPDATE profiles + DELETE/INSERT skills (full replace)
- **Avatar upload:** `uploadBinary` to `avatars/{uid}/avatar.{ext}` → get public URL → update `profiles.avatar_path`
- **KYC upload:** `upload` to `kyc-documents/{uid}/{type}/{file}` → INSERT `kyc_documents` row

### Job Requests
- **List:** SELECT from `job_requests` where `status = pending` — all handymen see all pending jobs
- **Accept:** UPDATE `job_requests` SET `status = accepted`, `provider_id = uid`
- **Reject:** UPDATE `job_requests` SET `status = rejected`
- **Details:** SELECT with `job_attachments` join for attachment paths
- **Watch (Realtime):** `.stream()` on `job_requests` where `status = pending`

### Wallet & Withdrawals
- **Balance fetch:** SELECT from `wallet` (select-first, insert-with-zero only if absent)
- **Stripe info:** Joined from `profiles` (stripe_account_id, stripe_payouts_enabled)
- **Withdrawal request:** INSERT into `withdrawals` → DB trigger deducts balance immediately
- **Rejection refund:** Admin updates `status = rejected` → DB trigger refunds balance
- **Actual payout:** Admin calls `process-withdrawal` edge function → Stripe transfer created
- **Bank details:** `get-stripe-bank-details` edge function (read-only display, not re-entered by user)

### Dashboard
- **Stats:** Today's earnings (SUM of `amount` for completed jobs today) + completed jobs count + pending count
- **Recent earnings:** `job_requests` WHERE `status = completed`, ordered by `completed_at DESC LIMIT 5`
- **All earnings:** Same query, no limit — separate `AllEarningsPage`
- **Recent job requests:** Pending jobs, limit 3 for dashboard preview

### Chat
- **Conversations list:** SELECT `conversations` WHERE `provider_id = uid`, join `profiles` for client name
- **Messages:** SELECT `messages` WHERE `conversation_id = id`, ordered by `created_at ASC`
- **Send message:** INSERT into `messages`, then UPDATE `conversations.last_message` and `last_message_at`
- **Live messages:** `.stream()` on `messages` filtered by `conversation_id`

---

## 11. App Navigation (GoRouter)

### Route Tree

```
/ (ShellRoute — PageWrapper with bottom nav)
├── /                        Dashboard
├── /wallet                  Wallet
│   └── /wallet/withdrawals  All Withdrawals
├── /earnings                All Earnings
├── /job-requests            Job Request List
├── /inbox                   Inbox (conversations list)
├── /profile                 Profile
└── /profile/edit            Edit Profile  [extra: Profile entity]

/login                       Login (guest only)
/registration                Registration
/registration/otp            OTP verification [extra: {identifier, isPhone, nextRoute}]
/registration/location       Location step
/registration/details        Personal details step
/registration/service-area   Service area + radius (Google Maps)
/registration/kyc-selection  KYC document type selection
/registration/kyc-upload     KYC document upload
/registration/terms          Terms & conditions
/job-request/details         Job request details [extra: JobRequest entity (TODO: pass id)]
/chat/:conversationId        Chat room
```

### Auth Guard
GoRouter `redirect` function checks `AuthBloc.state`:
- `AuthPendingApproval` → lock to `/login` (approval pending dialog shown there)
- `AuthAuthenticated` + on guest-only route → redirect to `/`
- Not authenticated + on protected route → redirect to `/login`
- Public routes (registration flow) → always accessible

### PageWrapper (ShellRoute)
Wraps authenticated pages with the bottom navigation bar. Bottom nav tabs: Dashboard, Inbox, Wallet, Profile.

---

## 12. Domain Entities

### `AppUser`
```dart
String id, String? phone, String? email
```

### `Profile`
```dart
String id, String name, String? phone, String? email, String? dob,
String? contractType,   // 'hourly' | 'contractual' | 'both'
double? hourlyRate, String? serviceArea,
double? serviceLat, double? serviceLng, int? serviceRadiusKm,
String? avatarPath, bool isOnline, bool isKycVerified,
List<String> skills
```

### `JobRequest`
```dart
String id, String clientId, String? clientName, String? providerId,
String category, String description,
String status,          // 'pending' | 'accepted' | 'rejected' | 'completed'
double clientLat, double clientLng,
String postedAt, List<String> attachmentPaths
```

### `Wallet`
```dart
String id, double balance, String? stripeAccountId, bool stripePayoutsEnabled
```

### `Withdrawal`
```dart
String id, String profileId, double amount,
String bankName, String accountLast4,
String status,          // 'pending' | 'completed' | 'rejected'
String createdAt
```

### `Conversation`
```dart
String id, String jobRequestId, String providerId, String clientId,
String? clientName, String? jobCategory,
String? lastMessage, String? lastMessageAt, int unreadCount
```

### `Message`
```dart
String id, String conversationId, String senderId, String text, String createdAt
```

### `Earning`
```dart
String id, String clientName, String jobCategory, double amount, String date
```

### `DashboardStats`
```dart
double todayEarnings, int completedJobs, int pendingRequests
```

---

## 13. BLoC Catalogue

| BLoC | Key Events | Key States |
|---|---|---|
| `AuthBloc` | `AuthCheckRequested`, `SendPhoneOtpRequested`, `VerifyPhoneOtpRequested`, `AuthSignOutRequested` | `AuthAuthenticated`, `AuthUnauthenticated`, `AuthPendingApproval`, `AuthOtpSent` |
| `ProfileBloc` | `ProfileFetchRequested`, `ProfileUpdateRequested`, `ProfileAvatarUploadRequested` | `ProfileLoaded`, `ProfileUpdating`, `ProfileUploadingAvatar`, `ProfileError` |
| `JobBloc` | `JobRequestsFetchRequested`, `JobRequestAccepted`, `JobRequestRejected` | `JobRequestsLoaded`, `JobActionSuccess`, `JobError` |
| `WalletBloc` | `WalletFetchRequested`, `WithdrawalRequested`, `ConnectStripeRequested` | `WalletLoaded`, `WithdrawalSuccess`, `StripeOnboardingUrlReady`, `WalletError` |
| `ChatBloc` | `ConversationsFetchRequested`, `MessagesFetchRequested`, `MessageSent` | `ConversationsLoaded`, `MessagesLoaded`, `ChatError` |
| `DashboardBloc` | `DashboardFetchRequested`, `AllEarningsFetchRequested`, `DashboardJobRequestsWatchStarted` | `DashboardLoaded`, `AllEarningsLoaded`, `DashboardError` |

---

## 14. Building the User (Client) App

### What the client app needs to do

| Feature | Description |
|---|---|
| Auth | Same Supabase project — phone OTP or email/password |
| Profile | Client profile in `profiles` table (no `contract_type`, `hourly_rate`, `service_radius_km`) |
| Post Job | INSERT into `job_requests` with `client_id`, `category`, `description`, `client_lat/lng` |
| Attach Photos | Upload to `job-attachments` bucket, INSERT into `job_attachments` |
| Track Jobs | SELECT own `job_requests` (where `client_id = uid`), watch status changes |
| Chat | Same `conversations` + `messages` tables — client side of the same chat |
| Payments | Client pays for jobs (Stripe PaymentIntents or Checkout — not yet in handyman app) |

### Shared DB — important rules

1. **`client_id` vs `provider_id`** — The handyman app filters by `provider_id`. The client app filters by `client_id`. Never confuse them.
2. **`profiles` is shared** — Clients also create a `profiles` row on signup. The distinguishing factor is `stripe_account_id` (only handymen have it) and `is_kyc_verified`.
3. **Job status ownership** — Only the handyman (`provider_id`) should update `status` to `accepted`/`rejected`/`completed`. The client should only read status, not write it.
4. **Conversations** — Created when a handyman accepts a job. Client app reads `conversations` filtered by `client_id`.
5. **Realtime** — Enable Realtime on `job_requests` for the client to watch status changes on their posted jobs.

### Recommended app structure

Use **identical project structure** to `luxihub_handyman`:
- Same `core/` layout (theme, router, DI, error handling)
- Same clean architecture per feature
- Same BLoC pattern
- Same package versions (see `pubspec.yaml`)

Copy `app_colors.dart` and `app_text_styles.dart` to keep consistent branding.

### Supabase RLS for client app

The existing RLS policies allow clients to:
- Read `job_requests` where `client_id = auth.uid()`
- Insert `job_requests` (any authenticated user)
- Read/write `conversations` where `client_id = auth.uid()`
- Read/write `messages` in their conversations

Verify these policies exist — add them if not:
```sql
-- Clients can see their own job requests
CREATE POLICY "Clients read own jobs"
ON job_requests FOR SELECT TO authenticated
USING (client_id = auth.uid());

-- Clients can post jobs
CREATE POLICY "Clients insert jobs"
ON job_requests FOR INSERT TO authenticated
WITH CHECK (client_id = auth.uid());
```

---

## 15. Environment Variables & Secrets

### Flutter app (`lib/core/config/`)
| File | Contains |
|---|---|
| `supabase_config.dart` | `url`, `anonKey` — **anon key only, safe to ship** |
| `maps_config.dart` | Google Maps API key — restrict to Android/iOS bundle IDs in GCP Console |

### Supabase Edge Functions (Deno env)
| Variable | Used By |
|---|---|
| `STRIPE_SECRET_KEY` | All Stripe edge functions |
| `SUPABASE_URL` | All edge functions |
| `SUPABASE_ANON_KEY` | Auth verification in edge functions |
| `SUPABASE_SERVICE_ROLE_KEY` | DB writes that bypass RLS (admin operations) |

Set via: `supabase secrets set STRIPE_SECRET_KEY=sk_live_...`

---

## 16. Key Conventions to Follow

1. **Use `maybeSingle()` not `single()`** when a row might not exist — `single()` throws on empty result.
2. **Never upsert with static field values** that should be preserved (e.g., `balance: 0`) — select first, insert only if absent.
3. **Skills replace, not patch** — delete all skills for a profile then re-insert. Do not diff.
4. **Avatar storage path** is always `{userId}/avatar.{ext}` with `upsert: true`. One file per user, same path overwrites.
5. **BLoC as factory** in GetIt — never singleton. Each page gets a fresh BLoC, disposes in `dispose()`.
6. **All money amounts** are stored as `numeric` in the DB (RM for local, EUR for Stripe transfers). Be explicit about currency in UI labels.
7. **`completed_at`** on `job_requests` drives all earnings calculations. Ensure it is set when status → `completed`.
8. **Stripe transfer currency** is `eur` in `process-withdrawal`. Change if operating in a different Stripe-supported currency.
9. **Deep link scheme** is `luxihub` (defined in `stripe-connect-return` edge function and Android/iOS config).
10. **Date formatting** — use `AppDateUtils.formatDob()` for display, `AppDateUtils.toServerDate()` for DB writes. No `intl` package dependency.
