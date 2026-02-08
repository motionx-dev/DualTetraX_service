# DualTetraX Services - OTA Firmware Management

**Version**: 1.0
**Date**: 2026-02-08

---

## 1. Overview

DualTetraX Services provides **Over-The-Air (OTA) firmware updates** for ESP32-based DualTetraX devices via **Mobile App + BLE**.

### 1.1 Update Flow

```
Admin uploads firmware → Server → Mobile App → BLE → Device
```

**Key Points**:
- Firmware hosted on **Supabase Storage** (secure, CDN)
- Mobile app downloads firmware over **HTTPS**
- Mobile app transfers firmware to device via **BLE**
- Per-user update history tracked in database

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       OTA Update Workflow                       │
└─────────────────────────────────────────────────────────────────┘

1. Admin (Web Console)
   ↓
   [Upload Firmware Binary]
   ↓
2. Vercel API (/api/admin/ota/upload-firmware)
   ↓
   - Validate file (checksum, size)
   - Upload to Supabase Storage (firmware-binaries bucket)
   - Create firmware_versions record
   - Create firmware_rollouts record (deployment strategy)
   ↓
3. Mobile App (Periodic Check)
   ↓
   [Check for Updates] (/api/ota/check-update)
   ↓
4. Server
   ↓
   - Query firmware_versions + firmware_rollouts
   - Check if device is eligible (rollout strategy)
   - Return presigned download URL (expires in 1 hour)
   ↓
5. Mobile App
   ↓
   - Show update notification to user
   - User approves update
   - Download firmware binary (HTTPS)
   - Verify checksum (SHA256)
   ↓
6. Mobile App → Device (BLE)
   ↓
   - Transfer firmware binary via BLE
   - Device writes to OTA partition (ESP-IDF OTA API)
   - Device reboots
   ↓
7. Device
   ↓
   - Boot into new firmware
   - Report new version via BLE
   ↓
8. Mobile App
   ↓
   - Detect new version
   - Report update status to server (/api/ota/report-status)
   ↓
9. Server
   ↓
   - Update device_firmware_status table
   - Create firmware_update_history record
   - Send success notification
```

---

## 3. Database Schema (Review)

### 3.1 firmware_versions

```sql
CREATE TABLE public.firmware_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT UNIQUE NOT NULL,               -- '1.0.24'
  version_code INT UNIQUE NOT NULL,           -- 10024
  storage_path TEXT NOT NULL,                 -- 'firmware-binaries/dualtetra-esp32-v1.0.24.bin'
  file_size_bytes BIGINT NOT NULL,
  checksum_sha256 TEXT NOT NULL,
  compatible_models TEXT[],
  changelog TEXT,                             -- Markdown format
  is_stable BOOLEAN DEFAULT FALSE,
  is_required BOOLEAN DEFAULT FALSE,          -- Force update
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3.2 firmware_rollouts

```sql
CREATE TABLE public.firmware_rollouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firmware_version_id UUID REFERENCES firmware_versions(id) NOT NULL,
  strategy TEXT NOT NULL CHECK (strategy IN ('all', 'gradual', 'manual', 'beta')),
  rollout_percentage INT DEFAULT 100,         -- 10, 50, 100
  target_tags TEXT[],                         -- ['beta', 'vip']
  target_device_ids UUID[],
  is_active BOOLEAN DEFAULT TRUE,
  start_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3.3 firmware_update_history

```sql
CREATE TABLE public.firmware_update_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) NOT NULL,
  pseudo_user_id UUID NOT NULL,              -- Privacy: no real_user_id
  from_version TEXT NOT NULL,
  to_version TEXT NOT NULL,
  status TEXT NOT NULL,                      -- 'success', 'failed', etc.
  update_initiated_at TIMESTAMP WITH TIME ZONE NOT NULL,
  update_completed_at TIMESTAMP WITH TIME ZONE,
  download_duration_ms INT,
  ble_transfer_duration_ms INT,
  ble_transfer_speed_kbps FLOAT,
  battery_level_at_start INT,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 4. API Endpoints

### 4.1 Upload Firmware (Admin Only)

**Endpoint**: `POST /api/admin/ota/upload-firmware`

**Request** (multipart/form-data):
```
POST /api/admin/ota/upload-firmware
Authorization: Bearer {admin_token}
Content-Type: multipart/form-data

{
  file: <binary>,
  version: "1.0.25",
  version_code: 10025,
  changelog: "## What's New\n- Bug fixes\n- New feature X",
  is_stable: true,
  is_required: false,
  compatible_models: ["DualTetraX Pro", "DualTetraX Lite"]
}
```

**Implementation**:
```typescript
// api/admin/ota/upload-firmware.ts
import { createClient } from '@supabase/supabase-js'
import crypto from 'crypto'

export async function POST(req: Request) {
  // 1. Verify admin role
  const supabase = createClient(...)
  const { user } = await supabase.auth.getUser()
  const { role } = await verifyAdminRole(user.id)

  if (role !== 'admin') {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  // 2. Parse form data
  const formData = await req.formData()
  const file = formData.get('file') as File
  const version = formData.get('version') as string
  const version_code = parseInt(formData.get('version_code'))

  // 3. Validate file
  if (!file.name.endsWith('.bin')) {
    return Response.json({ error: 'Invalid file type' }, { status: 400 })
  }

  // 4. Calculate checksum
  const buffer = await file.arrayBuffer()
  const checksum = crypto
    .createHash('sha256')
    .update(Buffer.from(buffer))
    .digest('hex')

  // 5. Upload to Supabase Storage
  const storage_path = `firmware-binaries/dualtetra-esp32-v${version}.bin`
  const { error: uploadError } = await supabase.storage
    .from('firmware-binaries')
    .upload(storage_path, buffer, {
      contentType: 'application/octet-stream',
      upsert: false
    })

  if (uploadError) {
    return Response.json({ error: uploadError.message }, { status: 500 })
  }

  // 6. Create firmware_versions record
  const { data: firmware, error } = await supabase
    .from('firmware_versions')
    .insert({
      version,
      version_code,
      storage_path,
      file_size_bytes: file.size,
      checksum_sha256: checksum,
      compatible_models: formData.get('compatible_models'),
      changelog: formData.get('changelog'),
      is_stable: formData.get('is_stable') === 'true',
      is_required: formData.get('is_required') === 'true',
      uploaded_by: user.id
    })
    .select()
    .single()

  return Response.json(firmware, { status: 201 })
}
```

---

### 4.2 Check for Updates (Mobile App)

**Endpoint**: `GET /api/ota/check-update?device_id={id}&current_version={version}`

**Implementation**:
```typescript
// api/ota/check-update.ts
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url)
  const device_id = searchParams.get('device_id')
  const current_version = searchParams.get('current_version')

  // 1. Get device info
  const { data: device } = await supabase
    .schema('analytics')
    .from('devices')
    .select('model_name, tags, pseudo_user_id')
    .eq('id', device_id)
    .single()

  // 2. Parse current version code
  const current_version_code = parseVersionCode(current_version) // e.g., '1.0.23' → 10023

  // 3. Find latest compatible firmware
  const { data: latestFirmware } = await supabase
    .from('firmware_versions')
    .select('*, firmware_rollouts!inner(*)')
    .eq('is_active', true)
    .contains('compatible_models', [device.model_name])
    .gt('version_code', current_version_code)
    .order('version_code', { ascending: false })
    .limit(1)
    .single()

  if (!latestFirmware) {
    return Response.json({ update_available: false })
  }

  // 4. Check rollout eligibility
  const rollout = latestFirmware.firmware_rollouts
  const isEligible = await checkRolloutEligibility(device, rollout)

  if (!isEligible) {
    return Response.json({ update_available: false })
  }

  // 5. Generate presigned download URL (expires in 1 hour)
  const { data: signedUrl } = await supabase.storage
    .from('firmware-binaries')
    .createSignedUrl(latestFirmware.storage_path, 3600)

  // 6. Return update info
  return Response.json({
    update_available: true,
    current_version,
    available_version: latestFirmware.version,
    available_version_code: latestFirmware.version_code,
    download_url: signedUrl.signedUrl,
    file_size_bytes: latestFirmware.file_size_bytes,
    checksum_sha256: latestFirmware.checksum_sha256,
    changelog: latestFirmware.changelog,
    is_required: latestFirmware.is_required,
    expires_at: new Date(Date.now() + 3600 * 1000).toISOString()
  })
}

// Helper: Check rollout eligibility
async function checkRolloutEligibility(device, rollout) {
  // Strategy: 'all' → everyone eligible
  if (rollout.strategy === 'all') {
    return true
  }

  // Strategy: 'beta' → only devices with 'beta' tag
  if (rollout.strategy === 'beta') {
    return device.tags?.includes('beta') || rollout.target_tags?.some(tag => device.tags?.includes(tag))
  }

  // Strategy: 'manual' → only specific device IDs
  if (rollout.strategy === 'manual') {
    return rollout.target_device_ids?.includes(device.id)
  }

  // Strategy: 'gradual' → random sampling based on percentage
  if (rollout.strategy === 'gradual') {
    const hash = hashString(device.pseudo_user_id) // Consistent hash
    const eligibilityThreshold = (rollout.rollout_percentage || 100) / 100
    return (hash % 100) / 100 < eligibilityThreshold
  }

  return false
}
```

---

### 4.3 Report Update Status (Mobile App)

**Endpoint**: `POST /api/ota/report-status`

**Request**:
```json
{
  "device_id": "device-uuid",
  "from_version": "1.0.23",
  "to_version": "1.0.24",
  "status": "success",
  "download_duration_ms": 15000,
  "ble_transfer_started_at": "2026-02-08T10:01:00Z",
  "ble_transfer_completed_at": "2026-02-08T10:03:00Z",
  "ble_transfer_speed_kbps": 11.67,
  "battery_level_at_start": 85,
  "error_message": null
}
```

**Implementation**:
```typescript
// api/ota/report-status.ts
export async function POST(req: Request) {
  const body = await req.json()
  const { device_id, from_version, to_version, status } = body

  // 1. Get device and pseudo_user_id
  const { data: device } = await supabase
    .schema('analytics')
    .from('devices')
    .select('pseudo_user_id')
    .eq('id', device_id)
    .single()

  // 2. Calculate BLE transfer duration
  const ble_transfer_duration_ms = body.ble_transfer_completed_at
    ? new Date(body.ble_transfer_completed_at).getTime() - new Date(body.ble_transfer_started_at).getTime()
    : null

  // 3. Insert update history
  const { data: history } = await supabase
    .from('firmware_update_history')
    .insert({
      device_id,
      pseudo_user_id: device.pseudo_user_id, // Privacy: no real_user_id
      from_version,
      from_version_code: parseVersionCode(from_version),
      to_version,
      to_version_code: parseVersionCode(to_version),
      status,
      update_initiated_at: new Date(Date.now() - body.download_duration_ms - ble_transfer_duration_ms).toISOString(),
      update_completed_at: status === 'success' ? new Date().toISOString() : null,
      download_duration_ms: body.download_duration_ms,
      ble_transfer_duration_ms,
      ble_transfer_speed_kbps: body.ble_transfer_speed_kbps,
      battery_level_at_start: body.battery_level_at_start,
      error_message: body.error_message
    })
    .select()
    .single()

  // 4. Update device_firmware_status
  if (status === 'success') {
    await supabase
      .from('device_firmware_status')
      .upsert({
        device_id,
        current_version: to_version,
        current_version_code: parseVersionCode(to_version),
        last_update_success_at: new Date().toISOString(),
        total_updates: supabase.raw('total_updates + 1')
      })

    // Also update devices table
    await supabase
      .schema('analytics')
      .from('devices')
      .update({
        firmware_version: to_version,
        firmware_updated_at: new Date().toISOString()
      })
      .eq('id', device_id)
  } else {
    // Failed update
    await supabase
      .from('device_firmware_status')
      .update({
        last_update_attempt_at: new Date().toISOString(),
        last_update_error: body.error_message
      })
      .eq('device_id', device_id)
  }

  // 5. Send notification (if success)
  if (status === 'success') {
    await sendNotification(device.pseudo_user_id, {
      title: 'Firmware Updated',
      body: `Your device has been updated to v${to_version}`,
      type: 'firmware_update'
    })
  }

  return Response.json({ message: 'Status recorded', history_id: history.id })
}
```

---

## 5. Mobile App Integration

### 5.1 Periodic Update Check

**Flutter (Background Task)**:
```dart
// lib/services/ota_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

class OTAService {
  final supabase = Supabase.instance.client;

  // Check for updates daily
  void scheduleUpdateCheck() {
    Workmanager().registerPeriodicTask(
      'ota-check',
      'checkForUpdates',
      frequency: Duration(days: 1),
    );
  }

  Future<UpdateInfo?> checkForUpdates(String deviceId, String currentVersion) async {
    final response = await supabase.functions.invoke(
      'check-update',
      queryParameters: {
        'device_id': deviceId,
        'current_version': currentVersion,
      },
    );

    final data = response.data;
    if (data['update_available'] == true) {
      return UpdateInfo.fromJson(data);
    }
    return null;
  }
}
```

---

### 5.2 Download Firmware

```dart
Future<File> downloadFirmware(String downloadUrl, String checksum) async {
  // 1. Download file
  final response = await http.get(Uri.parse(downloadUrl));
  final bytes = response.bodyBytes;

  // 2. Verify checksum
  final actualChecksum = sha256.convert(bytes).toString();
  if (actualChecksum != checksum) {
    throw Exception('Checksum mismatch! Possible corruption or tampering.');
  }

  // 3. Save to temp file
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/firmware.bin');
  await file.writeAsBytes(bytes);

  return file;
}
```

---

### 5.3 Transfer Firmware via BLE

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Future<void> transferFirmwareViaBLE(File firmwareFile, BluetoothDevice device) async {
  // 1. Read firmware file
  final bytes = await firmwareFile.readAsBytes();
  final totalSize = bytes.length;

  // 2. Find OTA characteristic
  final services = await device.discoverServices();
  final otaService = services.firstWhere((s) => s.uuid.toString() == OTA_SERVICE_UUID);
  final otaCharacteristic = otaService.characteristics.firstWhere(
    (c) => c.uuid.toString() == OTA_CHARACTERISTIC_UUID
  );

  // 3. Send firmware in chunks (MTU size, e.g., 512 bytes)
  const chunkSize = 512;
  int offset = 0;

  while (offset < totalSize) {
    final end = (offset + chunkSize < totalSize) ? offset + chunkSize : totalSize;
    final chunk = bytes.sublist(offset, end);

    await otaCharacteristic.write(chunk, withoutResponse: false);
    offset = end;

    // Update progress
    final progress = (offset / totalSize * 100).toInt();
    print('Transfer progress: $progress%');
  }

  // 4. Send completion signal
  await otaCharacteristic.write([0xFF], withoutResponse: false); // EOF marker

  print('Firmware transfer complete. Device will reboot.');
}
```

---

### 5.4 Report Status

```dart
Future<void> reportUpdateStatus({
  required String deviceId,
  required String fromVersion,
  required String toVersion,
  required String status,
  int? downloadDurationMs,
  DateTime? bleTransferStartedAt,
  DateTime? bleTransferCompletedAt,
  double? bleTransferSpeedKbps,
  int? batteryLevel,
  String? errorMessage,
}) async {
  await supabase.functions.invoke('report-status', body: {
    'device_id': deviceId,
    'from_version': fromVersion,
    'to_version': toVersion,
    'status': status,
    'download_duration_ms': downloadDurationMs,
    'ble_transfer_started_at': bleTransferStartedAt?.toIso8601String(),
    'ble_transfer_completed_at': bleTransferCompletedAt?.toIso8601String(),
    'ble_transfer_speed_kbps': bleTransferSpeedKbps,
    'battery_level_at_start': batteryLevel,
    'error_message': errorMessage,
  });
}
```

---

## 6. Firmware Rollout Strategies

### 6.1 All at Once (Risky)

**Use Case**: Critical bug fix, all devices must update immediately

```sql
INSERT INTO firmware_rollouts (firmware_version_id, strategy, rollout_percentage)
VALUES ('firmware-uuid', 'all', 100);
```

---

### 6.2 Gradual Rollout (Recommended)

**Use Case**: New feature, test on small group first

**Phase 1** (10%):
```sql
INSERT INTO firmware_rollouts (firmware_version_id, strategy, rollout_percentage)
VALUES ('firmware-uuid', 'gradual', 10);
```

**Phase 2** (50%, after 3 days if no issues):
```sql
UPDATE firmware_rollouts SET rollout_percentage = 50
WHERE firmware_version_id = 'firmware-uuid';
```

**Phase 3** (100%, after 7 days):
```sql
UPDATE firmware_rollouts SET rollout_percentage = 100
WHERE firmware_version_id = 'firmware-uuid';
```

---

### 6.3 Beta Group Only

**Use Case**: Experimental feature, only for beta testers

```sql
-- 1. Tag devices as beta
UPDATE analytics.devices SET tags = array_append(tags, 'beta')
WHERE id IN ('device-1', 'device-2', ...);

-- 2. Create beta rollout
INSERT INTO firmware_rollouts (firmware_version_id, strategy, target_tags)
VALUES ('firmware-uuid', 'beta', ARRAY['beta']);
```

---

### 6.4 Manual Selection

**Use Case**: Specific devices need urgent patch

```sql
INSERT INTO firmware_rollouts (firmware_version_id, strategy, target_device_ids)
VALUES ('firmware-uuid', 'manual', ARRAY['device-1', 'device-2']);
```

---

## 7. Admin Dashboard (Web)

### 7.1 Upload Firmware Page

**UI Components**:
- File upload (drag & drop)
- Version input (e.g., `1.0.25`)
- Version code input (e.g., `10025`)
- Changelog editor (Markdown)
- Compatibility selection (checkboxes)
- Stability toggle (Beta / Stable)
- Required toggle (Force update)

**Validation**:
- File must be `.bin`
- Version format: `x.y.z` (regex)
- Version code must be > latest
- File size < 10MB

---

### 7.2 Rollout Management Page

**Table Columns**:
- Firmware Version
- Strategy (All / Gradual / Beta / Manual)
- Rollout % (if gradual)
- Devices Eligible
- Devices Updated
- Success Rate
- Actions (Pause / Resume / Edit / Delete)

**Actions**:
- Pause rollout (emergency)
- Increase rollout percentage
- View update logs
- Rollback (deactivate current, activate previous)

---

### 7.3 Update History Dashboard

**Metrics**:
- Total updates today/week/month
- Success rate (%)
- Average download time
- Average BLE transfer speed
- Failed updates (with error details)

**Charts**:
- Update timeline (line chart)
- Firmware version distribution (pie chart)
- Success/failure breakdown (bar chart)

---

## 8. Security Considerations

### 8.1 Firmware Integrity

**Checksum Verification** (SHA256):
- Server calculates checksum on upload
- Mobile app verifies checksum after download
- Reject if mismatch (possible corruption or tampering)

---

### 8.2 Presigned URLs

**Expiration**: 1 hour
**Purpose**: Prevent unauthorized firmware downloads

---

### 8.3 Rollback Mechanism

**ESP32 OTA Partitions**:
- Two OTA partitions (ota_0, ota_1)
- If new firmware boots and fails, ESP32 can rollback to previous partition

**Server-side Rollback**:
- Admin can deactivate new firmware version
- Re-activate previous version
- All devices will be offered downgrade

---

## 9. Error Handling

### 9.1 Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Checksum mismatch | Corrupted download | Re-download firmware |
| BLE transfer timeout | Poor connection | Retry, move device closer |
| Device reboot failed | Firmware incompatible | Rollback to previous |
| Insufficient storage | OTA partition full | Firmware too large, reduce size |
| Low battery | < 20% battery | Require 30%+ battery |

---

### 9.2 Retry Logic

**Mobile App**:
- Retry download up to 3 times (exponential backoff)
- Retry BLE transfer up to 2 times
- Report failure after max retries

**Server**:
- Track retry count per device
- Flag devices with repeated failures for manual investigation

---

## 10. Monitoring & Alerts

### 10.1 Metrics to Track

- **Update Initiation Rate**: How many users start updates per day
- **Success Rate**: % of successful updates
- **Average Transfer Speed**: BLE transfer speed (kbps)
- **Failure Reasons**: Group by error_message

---

### 10.2 Alerts

**Slack Notifications**:
- New firmware uploaded
- Rollout paused (emergency)
- Success rate drops below 90%
- 10+ failed updates in 1 hour

---

**Document End**
