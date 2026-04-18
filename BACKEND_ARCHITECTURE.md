# LuxiHub Handyman — Supabase Backend Architecture

## Authentication

- **Provider:** Supabase Auth
- **Primary method:** Phone OTP (matches existing 2-step registration flow)
- **Fallback:** Email + password
- **Token management:** Handled automatically by `supabase_flutter` SDK — JWT persisted in secure storage, no manual token handling required

---

## Database Tables

### `profiles`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | References `auth.users.id` |
| `name` | `text` | |
| `phone` | `text` | |
| `email` | `text` | |
| `dob` | `date` | Date of birth |
| `contract_type` | `text` | e.g. Freelance, Full-time |
| `hourly_rate` | `numeric` | |
| `service_area` | `text` | City/region label |
| `service_lat` | `float8` | Map centre latitude |
| `service_lng` | `float8` | Map centre longitude |
| `service_radius_km` | `int` | |
| `avatar_path` | `text` | Storage path in `avatars` bucket |
| `is_online` | `bool` | Default `false` |
| `is_kyc_verified` | `bool` | Default `false` |
| `created_at` | `timestamptz` | Default `now()` |

---

### `skills`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `profile_id` | `uuid` | FK → `profiles.id` |
| `name` | `text` | e.g. Plumbing, Carpentry |

---

### `job_requests`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `client_id` | `uuid` | FK → `auth.users.id` |
| `provider_id` | `uuid` | FK → `profiles.id`, nullable until accepted |
| `category` | `text` | |
| `description` | `text` | Issue details message |
| `status` | `text` | `pending` · `accepted` · `rejected` · `completed` |
| `client_lat` | `float8` | |
| `client_lng` | `float8` | |
| `posted_at` | `timestamptz` | Default `now()` |

---

### `job_attachments`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `job_request_id` | `uuid` | FK → `job_requests.id` |
| `storage_path` | `text` | Path in `job-attachments` bucket |
| `uploaded_at` | `timestamptz` | Default `now()` |

---

### `conversations`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `job_request_id` | `uuid` | FK → `job_requests.id` |
| `provider_id` | `uuid` | FK → `profiles.id` |
| `client_id` | `uuid` | FK → `auth.users.id` |
| `last_message` | `text` | Denormalised for inbox list |
| `last_message_at` | `timestamptz` | |
| `unread_count` | `int` | Default `0` |

---

### `messages`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `conversation_id` | `uuid` | FK → `conversations.id` |
| `sender_id` | `uuid` | FK → `auth.users.id` |
| `text` | `text` | |
| `created_at` | `timestamptz` | Default `now()` |

---

### `wallet`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | References `profiles.id` (1-to-1) |
| `balance` | `numeric` | Default `0.00` |
| `updated_at` | `timestamptz` | |

---

### `withdrawals`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `profile_id` | `uuid` | FK → `profiles.id` |
| `amount` | `numeric` | |
| `bank_name` | `text` | |
| `account_last4` | `text` | |
| `status` | `text` | `pending` · `completed` · `failed` |
| `created_at` | `timestamptz` | Default `now()` |

---

### `kyc_documents`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` | |
| `profile_id` | `uuid` | FK → `profiles.id` |
| `type` | `text` | e.g. National ID, Passport, Driving Licence |
| `front_path` | `text` | Storage path |
| `back_path` | `text` | Storage path |
| `selfie_path` | `text` | Storage path |
| `status` | `text` | `pending` · `approved` · `rejected` |
| `submitted_at` | `timestamptz` | Default `now()` |

---

## Storage Buckets

| Bucket | Access | Used For |
|---|---|---|
| `avatars` | Authenticated read, owner write | Profile photos |
| `kyc-documents` | Owner only | KYC front/back/selfie uploads |
| `job-attachments` | Authenticated read, owner write | Photos attached to job requests |

---

## Realtime Subscriptions

| Table | Filter | Used In |
|---|---|---|
| `messages` | `conversation_id = eq.<id>` | `ChatPage` — live message stream |
| `job_requests` | `provider_id = eq.<uid>` | `DashboardPage` — live new job alerts |
| `conversations` | `provider_id = eq.<uid>` | `InboxPage` — live unread count updates |

---

## Row Level Security (RLS)

| Table | Policy |
|---|---|
| `profiles` | Users can read and write their own row only |
| `skills` | Users can read and write their own skills only |
| `job_requests` | Provider sees rows where `provider_id = auth.uid()` or status is `pending`; client sees own rows |
| `job_attachments` | Readable by job participants only |
| `conversations` | Readable/writable by `provider_id` or `client_id` only |
| `messages` | Readable/writable by conversation participants only |
| `wallet` | Users can read and write their own row only |
| `withdrawals` | Users can read and write their own rows only |
| `kyc_documents` | Users can read and write their own rows only |

---

## Flutter Clean Architecture Layer Mapping

Each feature maps Supabase to the existing `data/domain/presentation` structure:

```
features/<feature>/
  data/
    datasources/
      <feature>_remote_datasource.dart   ← Supabase SDK calls
    models/
      <feature>_model.dart               ← JSON serializable, extends entity
    repositories/
      <feature>_repository_impl.dart     ← implements domain interface
  domain/
    entities/
      <feature>.dart                     ← pure Dart, no dependencies
    repositories/
      <feature>_repository.dart          ← abstract interface
    usecases/
      get_<feature>.dart                 ← single-responsibility
      create_<feature>.dart
      update_<feature>.dart
  presentation/
    bloc/                                ← already scaffolded
    pages/
    widgets/
```

---

## Recommended Packages

```yaml
dependencies:
  supabase_flutter: ^2.8.0      # Auth + DB + Storage + Realtime
  flutter_bloc: ^9.1.0          # already scaffolded
  equatable: ^2.0.7             # already scaffolded
  freezed_annotation: ^3.0.0   # immutable models & BLoC states
  json_annotation: ^4.9.0      # JSON serialization
  injectable: ^2.5.0            # dependency injection
  get_it: ^8.0.0                # service locator for DI

dev_dependencies:
  freezed: ^3.0.0
  json_serializable: ^6.9.0
  injectable_generator: ^2.7.0
  build_runner: ^2.4.0
```

---

## Integration Sequence (Recommended Order)

1. **Auth** — replace registration/login flow with Supabase Auth OTP
2. **Profile** — create profile record post-registration, fetch on app start
3. **Job Requests** — replace dummy data, wire accept/reject actions
4. **Wallet** — fetch balance and withdrawals, implement withdrawal request
5. **Chat** — replace dummy messages with Realtime subscription on `messages`
6. **Inbox** — fetch conversations list, update `unread_count` on read
7. **KYC** — upload documents to storage, create `kyc_documents` record
8. **Notifications** — subscribe to `job_requests` Realtime for push alerts
