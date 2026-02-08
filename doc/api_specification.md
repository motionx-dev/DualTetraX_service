# DualTetraX Services - API Specification

**Version**: 1.0
**Date**: 2026-02-08
**Base URL (Production)**: `https://api.dualtetrax.com`
**Base URL (Staging)**: `https://api-staging.dualtetrax.com`

---

## 1. API Overview

### 1.1 Architecture
- **Primary API**: Supabase Auto-Generated REST API (PostgREST)
- **Custom API**: Vercel Serverless Functions (for complex logic)
- **Authentication**: JWT Bearer Token (Supabase Auth)
- **Format**: JSON
- **Protocol**: HTTPS only (TLS 1.3)

### 1.2 Base URLs

```
Supabase Auto API: https://[project-id].supabase.co/rest/v1/
Custom API (Vercel): https://api.dualtetrax.com/api/
```

---

## 2. Authentication

### 2.1 Sign Up

**Endpoint**: `POST /auth/v1/signup`
**Provider**: Supabase Auth

```http
POST https://[project-id].supabase.co/auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecureP@ssw0rd123"
}
```

**Response** (201 Created):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "created_at": "2026-02-08T12:00:00Z"
  }
}
```

---

### 2.2 Social Login (Google, Apple, Naver, Kakao)

**Endpoint**: `POST /auth/v1/authorize`

**Google Login**:
```http
POST https://[project-id].supabase.co/auth/v1/authorize
Content-Type: application/json

{
  "provider": "google",
  "redirect_to": "dualtetrax://callback"
}
```

**Kakao Login** (Korean users):
```http
POST /api/auth/kakao-login
Content-Type: application/json

{
  "access_token": "kakao_oauth_access_token"
}
```

**Naver Login** (Korean users):
```http
POST /api/auth/naver-login
Content-Type: application/json

{
  "access_token": "naver_oauth_access_token"
}
```

**Note**: Kakao/Naver OAuth는 Custom Vercel Function에서 처리 후 Supabase Auth 토큰 발급

---

### 2.3 Sign In

**Endpoint**: `POST /auth/v1/token?grant_type=password`

```http
POST https://[project-id].supabase.co/auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecureP@ssw0rd123"
}
```

**Response** (200 OK):
```json
{
  "access_token": "...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": { ... }
}
```

---

### 2.4 Logout (NEW - Security Fix)

**Endpoint**: `POST /api/auth/logout`

**Purpose**: Invalidate JWT token to prevent reuse after logout

```http
POST /api/auth/logout
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Implementation**:
```typescript
// Backend: Add token to blacklist
import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();

export async function POST(req: Request) {
  const token = extractToken(req.headers.get('authorization'));

  if (!token) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Add token to blacklist (expires in 1 hour, matching token TTL)
  await redis.set(`blacklist:${token}`, '1', { ex: 3600 });

  return Response.json({ message: 'Logged out successfully' });
}

// Verify token not blacklisted on every request
async function verifyToken(token: string) {
  const isBlacklisted = await redis.get(`blacklist:${token}`);

  if (isBlacklisted) {
    throw new Error('Token has been revoked');
  }

  // Continue with normal JWT verification
}
```

**Response** (200 OK):
```json
{
  "message": "Logged out successfully"
}
```

**Security Note**: This prevents stolen tokens from being used after logout. Tokens are automatically removed from blacklist after 1 hour (access token TTL).

---

### 2.5 Password Reset (Email)

**Endpoint**: `POST /auth/v1/recover`

```http
POST https://[project-id].supabase.co/auth/v1/recover
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response** (200 OK):
```json
{
  "message": "Password reset email sent"
}
```

---

### 2.5 Password Reset (SMS via Kakao) - NEW

**Endpoint**: `POST /api/auth/reset-password-sms`

```http
POST /api/auth/reset-password-sms
Content-Type: application/json

{
  "phone_number": "+821012345678"
}
```

**Response** (200 OK):
```json
{
  "message": "Verification code sent via Kakao message",
  "expires_in": 300
}
```

**Verify Code and Reset**:
```http
POST /api/auth/verify-and-reset
Content-Type: application/json

{
  "phone_number": "+821012345678",
  "verification_code": "123456",
  "new_password": "NewP@ssw0rd123"
}
```

---

### 2.6 Token Refresh

**Endpoint**: `POST /auth/v1/token?grant_type=refresh_token`

```http
POST https://[project-id].supabase.co/auth/v1/token?grant_type=refresh_token
Content-Type: application/json

{
  "refresh_token": "..."
}
```

---

## 3. User Profile API

### 3.1 Get My Profile

**Endpoint**: `GET /rest/v1/profiles?id=eq.{user_id}`
**Auth**: Required (Bearer token)

```http
GET /rest/v1/profiles?id=eq.550e8400-e29b-41d4-a716-446655440000&select=*
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "profile_image_url": "https://...",
  "phone_number": "+821012345678",
  "push_notifications_enabled": true,
  "created_at": "2026-01-01T00:00:00Z"
}
```

**Security**: Row Level Security (RLS) ensures users can only access their own profile.

---

### 3.2 Update Profile

**Endpoint**: `PATCH /rest/v1/profiles?id=eq.{user_id}`

```http
PATCH /rest/v1/profiles?id=eq.550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "name": "Jane Doe",
  "profile_image_url": "https://...",
  "push_notifications_enabled": false
}
```

**Response** (200 OK):
```json
{
  "id": "...",
  "name": "Jane Doe",
  "updated_at": "2026-02-08T12:30:00Z"
}
```

---

## 4. Device Management API

### 4.1 Register Device

**Endpoint**: `POST /rest/v1/devices`

```http
POST /rest/v1/devices
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "serial_number": "DTX-2024-001234",
  "model_name": "DualTetraX Pro",
  "firmware_version": "1.0.23",
  "ble_mac_address": "AA:BB:CC:DD:EE:FF"
}
```

**Response** (201 Created):
```json
{
  "id": "device-uuid",
  "user_id": "user-uuid",
  "serial_number": "DTX-2024-001234",
  "model_name": "DualTetraX Pro",
  "firmware_version": "1.0.23",
  "is_active": true,
  "registered_at": "2026-02-08T12:00:00Z"
}
```

**Error Cases**:
- `409 Conflict`: Serial number already registered
- `400 Bad Request`: Invalid serial number format

---

### 4.2 Get My Devices

**Endpoint**: `GET /rest/v1/devices?user_id=eq.{user_id}&select=*`

```http
GET /rest/v1/devices?user_id=eq.{user_id}&select=*&order=registered_at.desc
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
[
  {
    "id": "device-uuid",
    "serial_number": "DTX-2024-001234",
    "model_name": "DualTetraX Pro",
    "firmware_version": "1.0.23",
    "last_connected_at": "2026-02-08T11:00:00Z",
    "is_active": true
  }
]
```

---

### 4.3 Update Device Heartbeat

**Endpoint**: `PATCH /rest/v1/devices?id=eq.{device_id}`

```http
PATCH /rest/v1/devices?id=eq.{device_id}
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "last_connected_at": "2026-02-08T12:00:00Z",
  "connection_count": 15
}
```

---

### 4.4 Delete Device

**Endpoint**: `DELETE /rest/v1/devices?id=eq.{device_id}`

```http
DELETE /rest/v1/devices?id=eq.{device_id}
Authorization: Bearer {access_token}
```

**Response** (204 No Content)

---

## 5. Usage Sessions API

### 5.1 Upload Usage Sessions (Batch)

**Endpoint**: `POST /rest/v1/usage_sessions`

```http
POST /rest/v1/usage_sessions
Authorization: Bearer {access_token}
Content-Type: application/json

[
  {
    "device_id": "device-uuid",
    "shot_type": "USHOT",
    "device_mode": "GLOW",
    "level": 2,
    "start_time": "2026-02-08T10:00:00Z",
    "end_time": "2026-02-08T10:10:00Z",
    "working_duration": 600,
    "pause_duration": 0,
    "battery_start": 80,
    "battery_end": 78,
    "warning_occurred": false,
    "local_session_id": "mobile-session-12345"
  },
  {
    "device_id": "device-uuid",
    "shot_type": "ESHOT",
    "device_mode": "TONEUP",
    "level": 3,
    "start_time": "2026-02-08T11:00:00Z",
    "end_time": "2026-02-08T11:08:00Z",
    "working_duration": 480,
    "pause_duration": 0,
    "battery_start": 78,
    "battery_end": 76,
    "warning_occurred": false,
    "local_session_id": "mobile-session-12346"
  }
]
```

**Response** (201 Created):
```json
[
  {
    "id": "session-uuid-1",
    "device_id": "device-uuid",
    "created_at": "2026-02-08T12:00:00Z"
  },
  {
    "id": "session-uuid-2",
    "device_id": "device-uuid",
    "created_at": "2026-02-08T12:00:00Z"
  }
]
```

**Note**: `local_session_id`로 중복 방지 (UNIQUE 제약조건)

---

### 5.2 Get My Sessions

**Endpoint**: `GET /rest/v1/usage_sessions?user_id=eq.{user_id}&select=*&order=start_time.desc&limit=50`

```http
GET /rest/v1/usage_sessions?user_id=eq.{user_id}&select=*&order=start_time.desc&limit=50
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
[
  {
    "id": "session-uuid",
    "device_id": "device-uuid",
    "shot_type": "USHOT",
    "device_mode": "GLOW",
    "level": 2,
    "start_time": "2026-02-08T10:00:00Z",
    "working_duration": 600,
    "battery_start": 80
  }
]
```

---

### 5.3 Delete Session

**Endpoint**: `DELETE /rest/v1/usage_sessions?id=eq.{session_id}`

```http
DELETE /rest/v1/usage_sessions?id=eq.{session_id}
Authorization: Bearer {access_token}
```

---

## 6. Statistics API

### 6.1 Get Daily Statistics

**Endpoint**: `GET /rest/v1/daily_statistics?user_id=eq.{user_id}&stat_date=gte.2026-02-01&stat_date=lte.2026-02-08&order=stat_date.desc`

```http
GET /rest/v1/daily_statistics?user_id=eq.{user_id}&stat_date=gte.2026-02-01&order=stat_date.desc
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
[
  {
    "stat_date": "2026-02-08",
    "total_sessions": 5,
    "total_working_duration": 3000,
    "ushot_duration": 1800,
    "eshot_duration": 1200,
    "led_duration": 0
  },
  {
    "stat_date": "2026-02-07",
    "total_sessions": 3,
    "total_working_duration": 1800,
    "ushot_duration": 1200,
    "eshot_duration": 600,
    "led_duration": 0
  }
]
```

---

### 6.2 Get Weekly/Monthly Statistics (Custom API)

**Endpoint**: `GET /api/analytics/stats?period=weekly&start_date=2026-02-01`

```http
GET /api/analytics/stats?period=weekly&start_date=2026-02-01
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "period": "weekly",
  "start_date": "2026-02-01",
  "end_date": "2026-02-08",
  "total_sessions": 15,
  "total_duration": 9000,
  "daily_breakdown": [
    { "date": "2026-02-01", "sessions": 2, "duration": 1200 },
    { "date": "2026-02-02", "sessions": 3, "duration": 1800 },
    ...
  ],
  "shot_type_breakdown": {
    "USHOT": { "sessions": 8, "duration": 4800 },
    "ESHOT": { "sessions": 7, "duration": 4200 }
  },
  "mode_breakdown": {
    "GLOW": 3000,
    "TONEUP": 2400,
    "RENEW": 1800
  }
}
```

---

## 7. OTA Firmware API

### 7.1 Check for Updates

**Endpoint**: `GET /api/ota/check-update?device_id={device_id}`

```http
GET /api/ota/check-update?device_id={device_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK) - Update Available:
```json
{
  "update_available": true,
  "current_version": "1.0.23",
  "available_version": "1.0.24",
  "available_version_code": 10024,
  "download_url": "https://[project-id].supabase.co/storage/v1/object/sign/firmware-binaries/dualtetra-esp32-v1.0.24.bin?token=...",
  "file_size_bytes": 1400000,
  "checksum_sha256": "abc123...",
  "changelog": "## What's New\n- Bug fixes\n- Performance improvements",
  "is_required": false,
  "expires_at": "2026-02-08T13:00:00Z"
}
```

**Response** (200 OK) - No Update:
```json
{
  "update_available": false,
  "current_version": "1.0.24",
  "message": "Your device is up to date"
}
```

---

### 7.2 Report Update Status

**Endpoint**: `POST /api/ota/report-status`

```http
POST /api/ota/report-status
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "device_id": "device-uuid",
  "from_version": "1.0.23",
  "to_version": "1.0.24",
  "status": "success",
  "download_duration_ms": 15000,
  "ble_transfer_duration_ms": 120000,
  "ble_transfer_speed_kbps": 11.67,
  "battery_level_at_start": 85
}
```

**Response** (200 OK):
```json
{
  "message": "Update status recorded",
  "history_id": "history-uuid"
}
```

**Status Values**: `initiated`, `downloading`, `transferring`, `installing`, `success`, `failed`, `cancelled`

---

### 7.3 Get Firmware Update History

**Endpoint**: `GET /rest/v1/firmware_update_history?user_id=eq.{user_id}&select=*&order=update_initiated_at.desc&limit=10`

```http
GET /rest/v1/firmware_update_history?user_id=eq.{user_id}&select=*&order=update_initiated_at.desc&limit=10
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
[
  {
    "id": "history-uuid",
    "device_id": "device-uuid",
    "from_version": "1.0.23",
    "to_version": "1.0.24",
    "status": "success",
    "update_initiated_at": "2026-02-08T10:00:00Z",
    "update_completed_at": "2026-02-08T10:03:00Z",
    "ble_transfer_speed_kbps": 11.67
  }
]
```

---

### 7.4 Upload Firmware (Admin Only)

**Endpoint**: `POST /api/admin/ota/upload-firmware`

```http
POST /api/admin/ota/upload-firmware
Authorization: Bearer {admin_access_token}
Content-Type: multipart/form-data

{
  "file": <binary>,
  "version": "1.0.25",
  "version_code": 10025,
  "changelog": "Major update with new features",
  "is_stable": true,
  "compatible_models": ["DualTetraX Pro", "DualTetraX Lite"]
}
```

**Response** (201 Created):
```json
{
  "firmware_version_id": "firmware-uuid",
  "version": "1.0.25",
  "storage_path": "firmware-binaries/dualtetra-esp32-v1.0.25.bin",
  "checksum_sha256": "def456..."
}
```

---

## 8. Personalization API

### 8.1 Get Skin Profile

**Endpoint**: `GET /rest/v1/skin_profiles?user_id=eq.{user_id}`

```http
GET /rest/v1/skin_profiles?user_id=eq.{user_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "user_id": "user-uuid",
  "skin_type": "combination",
  "concerns": ["wrinkles", "elasticity"],
  "preferred_shot_type": "USHOT",
  "preferred_modes": ["GLOW", "RENEW"],
  "weekly_goal_sessions": 3
}
```

---

### 8.2 Update Skin Profile

**Endpoint**: `PATCH /rest/v1/skin_profiles?user_id=eq.{user_id}`

```http
PATCH /rest/v1/skin_profiles?user_id=eq.{user_id}
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "skin_type": "dry",
  "concerns": ["wrinkles", "pigmentation"],
  "weekly_goal_sessions": 4
}
```

---

### 8.3 Get Recommendations

**Endpoint**: `GET /api/recommendations?user_id={user_id}`

```http
GET /api/recommendations?user_id={user_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
[
  {
    "id": "rec-uuid",
    "recommendation_type": "mode",
    "recommended_value": {
      "mode": "RENEW",
      "level": 3,
      "frequency": "3 times per week"
    },
    "reason": "Based on your skin type (dry) and concerns (wrinkles), RENEW mode Level 3 is recommended.",
    "confidence_score": 0.85,
    "shown_at": "2026-02-08T12:00:00Z"
  }
]
```

---

## 9. Admin API

### 9.1 Get All Users (Admin)

**Endpoint**: `GET /api/admin/users?page=1&limit=50&search=&filter=`

```http
GET /api/admin/users?page=1&limit=50&search=john
Authorization: Bearer {admin_access_token}
```

**Response** (200 OK):
```json
{
  "total": 1234,
  "page": 1,
  "limit": 50,
  "data": [
    {
      "id": "user-uuid",
      "email": "john@example.com",
      "name": "John Doe",
      "role": "user",
      "is_active": true,
      "device_count": 2,
      "last_login_at": "2026-02-08T11:00:00Z",
      "created_at": "2026-01-01T00:00:00Z"
    }
  ]
}
```

---

### 9.2 Get All Devices (Admin)

**Endpoint**: `GET /api/admin/devices?page=1&limit=100&firmware_version=1.0.23`

```http
GET /api/admin/devices?page=1&limit=100&firmware_version=1.0.23
Authorization: Bearer {admin_access_token}
```

**Response** (200 OK):
```json
{
  "total": 1000,
  "page": 1,
  "limit": 100,
  "data": [
    {
      "id": "device-uuid",
      "serial_number": "DTX-2024-001234",
      "user_email": "user@example.com",
      "firmware_version": "1.0.23",
      "last_connected_at": "2026-02-08T10:00:00Z",
      "connection_count": 50
    }
  ]
}
```

---

### 9.3 System Dashboard (Admin)

**Endpoint**: `GET /api/admin/dashboard`

```http
GET /api/admin/dashboard
Authorization: Bearer {admin_access_token}
```

**Response** (200 OK):
```json
{
  "total_users": 1234,
  "active_users_7d": 890,
  "total_devices": 1000,
  "active_devices_7d": 750,
  "total_sessions_today": 3500,
  "firmware_distribution": {
    "1.0.24": 600,
    "1.0.23": 300,
    "1.0.22": 100
  },
  "update_success_rate": 0.98
}
```

---

## 10. Security & Error Handling

### 10.1 Authentication Errors

**401 Unauthorized**:
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

**403 Forbidden**:
```json
{
  "error": "Forbidden",
  "message": "You do not have permission to access this resource"
}
```

---

### 10.2 Rate Limiting

**429 Too Many Requests**:
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again later.",
  "retry_after": 60
}
```

**Limits**:
- Unauthenticated: 20 req/min per IP
- Authenticated: 100 req/min per user
- Admin: 500 req/min

---

### 10.3 Validation Errors

**400 Bad Request**:
```json
{
  "error": "Validation error",
  "details": [
    {
      "field": "email",
      "message": "Invalid email format"
    },
    {
      "field": "password",
      "message": "Password must be at least 8 characters"
    }
  ]
}
```

---

### 10.4 Server Errors

**500 Internal Server Error**:
```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred. Please try again later.",
  "request_id": "req-uuid"
}
```

---

## 11. API Client Examples

### 11.1 Flutter (Supabase SDK)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Sign in
final AuthResponse res = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password',
);

// Get devices
final devices = await supabase
  .from('devices')
  .select()
  .eq('user_id', supabase.auth.currentUser!.id);

// Upload sessions
await supabase.from('usage_sessions').insert([
  {
    'device_id': deviceId,
    'shot_type': 'USHOT',
    'start_time': DateTime.now().toIso8601String(),
    // ...
  }
]);
```

---

### 11.2 Next.js (JavaScript)

```javascript
import { createBrowserClient } from '@supabase/ssr'

const supabase = createBrowserClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
)

// Get daily stats
const { data, error } = await supabase
  .from('daily_statistics')
  .select('*')
  .eq('user_id', userId)
  .gte('stat_date', '2026-02-01')
  .order('stat_date', { ascending: false })
```

---

## 12. Webhooks (Future)

### 12.1 Firmware Update Completed

**Endpoint**: Configured by user
**Method**: POST
**Payload**:

```json
{
  "event": "firmware.update.completed",
  "device_id": "device-uuid",
  "from_version": "1.0.23",
  "to_version": "1.0.24",
  "status": "success",
  "timestamp": "2026-02-08T12:00:00Z"
}
```

---

**Document End**
