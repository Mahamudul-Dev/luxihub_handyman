 Send Notification — Edge Function

Send in-app notifications to a specific user or all users on the LuxiHub platform.

---

## Table of Contents

- [Setup](#setup)
- [Authentication](#authentication)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Notification Types](#notification-types)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Setup

### 1. Choose an Admin API Key

Generate a strong random string to use as your secret key. This key protects the endpoint — keep it private.

Example (do not use this exact value):
```
nXk9pR2mQv7Yc4tA8bLdZw3eJhFuGs6
```

### 2. Set the Secret in Supabase

```bash
supabase secrets set ADMIN_API_KEY=your_random_key_here
```

### 3. Deploy the Function

```bash
supabase functions deploy send-notification --no-verify-jwt
```

> `--no-verify-jwt` is required because this function is called by you (the admin), not by app users who carry a Supabase JWT.

### 4. Find Your Function URL

```
https://<your-project-ref>.supabase.co/functions/v1/send-notification
```

Replace `<your-project-ref>` with your Supabase project reference ID.  
You can find it in: **Supabase Dashboard → Settings → General → Reference ID**

---

## Authentication

Every request must include your `ADMIN_API_KEY` in the `Authorization` header:

```
Authorization: Bearer your_random_key_here
```

Requests without this header, or with an incorrect key, receive a `401 Unauthorized` response.

> **Never expose this key in the Flutter app or any public-facing code.**

---

## API Reference

### Endpoint

```
POST /functions/v1/send-notification
```

### Headers

| Header | Required | Value |
|---|---|---|
| `Authorization` | ✅ Yes | `Bearer <ADMIN_API_KEY>` |
| `Content-Type` | ✅ Yes | `application/json` |

### Request Body

| Field | Type | Required | Description |
|---|---|---|---|
| `title` | `string` | ✅ Yes | Notification heading shown in the app |
| `body` | `string` | ✅ Yes | Notification message text |
| `type` | `string` | ❌ No (default: `general`) | One of: `general`, `job_update`, `payment`, `system` |
| `targetUserId` | `string` (UUID) | ❌ No | Profile UUID of the target user. **Omit or set `null` to send to all users** |
| `data` | `object` | ❌ No | Optional JSON metadata (e.g. `jobRequestId` for deep linking) |

### Response — Success `200`

```json
{
  "success": true,
  "notificationId": "a1b2c3d4-...",
  "sentTo": "all"
}
```

```json
{
  "success": true,
  "notificationId": "a1b2c3d4-...",
  "sentTo": "user:81d0537d-57d8-4d80-98f0-716a04e1f0fe"
}
```

### Response — Error

| Status | Reason |
|---|---|
| `400` | Missing or invalid fields in the request body |
| `401` | Missing or incorrect `ADMIN_API_KEY` |
| `404` | `targetUserId` does not exist in the `profiles` table |
| `500` | Database insert failed (check Supabase logs) |

---

## Examples

### Send to All Users

```bash
curl -X POST https://<ref>.supabase.co/functions/v1/send-notification \
  -H "Authorization: Bearer your_random_key_here" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "System Maintenance",
    "body": "LuxiHub will be briefly offline tonight at 11pm for scheduled maintenance.",
    "type": "system"
  }'
```

---

### Send to a Specific User

```bash
curl -X POST https://<ref>.supabase.co/functions/v1/send-notification \
  -H "Authorization: Bearer your_random_key_here" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Job Accepted!",
    "body": "A handyman has accepted your plumbing request.",
    "type": "job_update",
    "targetUserId": "81d0537d-57d8-4d80-98f0-716a04e1f0fe"
  }'
```

---

### Send with Metadata (for deep linking)

```bash
curl -X POST https://<ref>.supabase.co/functions/v1/send-notification \
  -H "Authorization: Bearer your_random_key_here" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Payment Confirmed",
    "body": "Your payment of £300 has been received successfully.",
    "type": "payment",
    "targetUserId": "81d0537d-57d8-4d80-98f0-716a04e1f0fe",
    "data": {
      "jobRequestId": "abc-123-def-456"
    }
  }'
```

---

### Postman Setup

1. Create a new **POST** request
2. URL: `https://<ref>.supabase.co/functions/v1/send-notification`
3. **Headers tab:**
   - `Authorization` → `Bearer your_random_key_here`
   - `Content-Type` → `application/json`
4. **Body tab:** select **raw → JSON**, paste the request body
5. Click **Send**

---

## Notification Types

The `type` field controls the icon and colour shown in the app.

| Value | Icon | Colour | Use for |
|---|---|---|---|
| `general` | 🔔 Bell | Green (primary) | Announcements, promotions, general updates |
| `job_update` | 💼 Briefcase | Green (primary) | Job accepted, rejected, or completed |
| `payment` | 💳 Card | Green (dark) | Payment confirmed or failed |
| `system` | ⚙️ Gear | Blue-grey | Maintenance, app updates, policy changes |

---

## How the App Receives Notifications

| Scenario | Behaviour |
|---|---|
| **App is open** | Notification appears instantly via Supabase Realtime (WebSocket) |
| **App is in background / closed** | Currently not delivered (FCM integration needed for push) |

**Unread indicator:** Each notification shows a blue dot until the user taps it.  
**Mark all read:** Users can tap "Mark all read" in the AppBar to clear all at once.

---

## Finding a User's Profile UUID

To send to a specific user you need their `profiles.id` (UUID).  
Look it up in: **Supabase Dashboard → Table Editor → profiles**

Or run this SQL:

```sql
SELECT id, name, email
FROM profiles
WHERE email = 'user@example.com';
```

---

## Troubleshooting

### `401 Unauthorized`
- Verify your `ADMIN_API_KEY` secret was set correctly:
  ```bash
  supabase secrets list
  ```
- Make sure the `Authorization` header value is exactly `Bearer <key>` with no extra spaces.

### `404 User not found`
- The `targetUserId` must match a row in the `profiles` table, not `auth.users`.
- Confirm the UUID is correct via the Supabase Dashboard.

### Notification not appearing in app
- Check that the `notifications` table has Realtime enabled:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  ```
- Confirm the app is running and the user is authenticated.
- Check Supabase Edge Function logs: **Dashboard → Edge Functions → send-notification → Logs**

### `500 Internal Server Error`
- Check function logs in the Supabase Dashboard.
- Confirm the `notifications` table exists and the RLS `service_role_insert_notifications` policy is in place.

---

## Future: Background Push Notifications (FCM)

The current implementation delivers notifications in-app only (Realtime).  
To support background push when the app is closed, the roadmap is:

1. Integrate **Firebase Cloud Messaging (FCM)** into the Flutter app
2. Store each user's **FCM device token** in a `device_tokens` table
3. Add a **Supabase Database Webhook** on `notifications INSERT` → calls a new edge function
4. The new edge function reads the target user's token(s) and calls the **FCM API**

This can be added without changing the current `send-notification` function or the `notifications` table schema.
