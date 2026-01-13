# Firmware Management Design

## Document Info
- **Version**: 1.0
- **Date**: 2026-01-13
- **Project**: DualTetraX Mobile App - Firmware Management

---

## 1. Overview

### 1.0 Deployment Stages

| Stage | Name | Infrastructure | Use Case |
|-------|------|----------------|----------|
| **1** | Local | 모바일 앱 단독 | 개발/OTA 테스트 |
| **2** | MVP | Oracle Cloud (단일 인스턴스) | 초기 서비스 운영 |
| **3** | Production | AWS (완전 관리형) | 상용 서비스 |

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Mobile App                                   │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    FirmwareRepository                          │ │
│  │  ┌───────────────┐ ┌───────────────┐ ┌───────────────────┐   │ │
│  │  │ LocalFile     │ │ OracleCloud   │ │ AWS S3            │   │ │
│  │  │ DataSource    │ │ DataSource    │ │ DataSource        │   │ │
│  │  │ (Stage 1)     │ │ (Stage 2)     │ │ (Stage 3)         │   │ │
│  │  └───────┬───────┘ └───────┬───────┘ └─────────┬─────────┘   │ │
│  └──────────┼─────────────────┼───────────────────┼─────────────┘ │
│             │                 │                   │                │
│             ▼                 ▼                   ▼                │
│        File Picker      Oracle VM API       AWS S3 API            │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.1 Stage Comparison

| Feature | Stage 1 (Local) | Stage 2 (Oracle) | Stage 3 (AWS) |
|---------|-----------------|------------------|---------------|
| 펌웨어 저장소 | 로컬 파일 | VM 디스크 | S3 |
| 버전 관리 | 파일명 | PostgreSQL | DynamoDB |
| API 서버 | - | FastAPI/Go | API Gateway + Lambda |
| 사용자 관리 | - | PostgreSQL | Cognito |
| 단말 관리 | - | PostgreSQL | DynamoDB |
| 비용 | 무료 | ~$0 (Free Tier) | ~$5/월 |
| 확장성 | - | 제한적 | 무제한 |

---

## 2. Stage 2: Oracle Cloud MVP

### 2.1 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Oracle Cloud (Free Tier)                      │
│                    Single VM Instance (ARM)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Docker Compose                         │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐ │  │
│  │  │   Nginx    │  │  FastAPI   │  │    PostgreSQL      │ │  │
│  │  │  (Reverse  │──│  (REST     │──│  - Users           │ │  │
│  │  │   Proxy)   │  │   API)     │  │  - Devices         │ │  │
│  │  │  :443      │  │  :8000     │  │  - Firmware Meta   │ │  │
│  │  └────────────┘  └────────────┘  └────────────────────┘ │  │
│  │                        │                                  │  │
│  │                  ┌─────┴─────┐                           │  │
│  │                  │  /data    │                           │  │
│  │                  │ (Volume)  │                           │  │
│  │                  │ Firmware  │                           │  │
│  │                  │  Files    │                           │  │
│  │                  └───────────┘                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
                       ┌─────────────┐
                       │ Mobile App  │
                       └─────────────┘
```

### 2.2 Oracle Cloud Free Tier Specs

| Resource | Spec | Note |
|----------|------|------|
| VM | ARM (Ampere A1) | 4 OCPU, 24GB RAM |
| Storage | 200GB Block Volume | 펌웨어 + DB |
| Network | 10TB/월 Outbound | 충분 |
| 비용 | **무료** | Always Free |

### 2.3 Database Schema (PostgreSQL)

```sql
-- Users 테이블
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- Devices 테이블
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id),
    model VARCHAR(50) DEFAULT 'DualTetraX',
    hw_version VARCHAR(20),
    fw_version VARCHAR(20),
    registered_at TIMESTAMP DEFAULT NOW(),
    last_seen TIMESTAMP
);

-- Firmware 테이블
CREATE TABLE firmware (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(20) UNIQUE NOT NULL,
    build_number INTEGER NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    file_size INTEGER NOT NULL,
    md5_checksum VARCHAR(32) NOT NULL,
    release_notes_ko TEXT,
    release_notes_en TEXT,
    min_hw_version VARCHAR(20),
    is_mandatory BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    channel VARCHAR(20) DEFAULT 'production',
    created_at TIMESTAMP DEFAULT NOW()
);

-- OTA History 테이블
CREATE TABLE ota_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(id),
    from_version VARCHAR(20),
    to_version VARCHAR(20),
    status VARCHAR(20), -- 'success', 'failed', 'cancelled'
    error_message TEXT,
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);
```

### 2.4 REST API (FastAPI)

```python
# app/main.py

from fastapi import FastAPI, HTTPException, Depends
from fastapi.responses import FileResponse
import os

app = FastAPI(title="DualTetraX Service API")

FIRMWARE_DIR = "/data/firmware"

# ─────────────────────────────────────────────────────────
# Firmware Endpoints
# ─────────────────────────────────────────────────────────

@app.post("/api/v1/firmware/check-update")
async def check_update(request: UpdateCheckRequest, db: Session = Depends(get_db)):
    """현재 버전과 최신 버전 비교"""
    latest = db.query(Firmware)\
        .filter(Firmware.is_active == True)\
        .filter(Firmware.channel == request.channel)\
        .order_by(Firmware.build_number.desc())\
        .first()

    if not latest or latest.version <= request.current_version:
        return {"update_available": False}

    return {
        "update_available": True,
        "latest_version": latest.version,
        "file_size": latest.file_size,
        "is_mandatory": latest.is_mandatory,
        "release_notes": {
            "ko": latest.release_notes_ko,
            "en": latest.release_notes_en
        }
    }

@app.get("/api/v1/firmware/{version}/download")
async def download_firmware(version: str, db: Session = Depends(get_db)):
    """펌웨어 파일 다운로드"""
    firmware = db.query(Firmware).filter(Firmware.version == version).first()
    if not firmware:
        raise HTTPException(404, "Version not found")

    file_path = os.path.join(FIRMWARE_DIR, firmware.file_path)
    if not os.path.exists(file_path):
        raise HTTPException(404, "Firmware file not found")

    return FileResponse(
        file_path,
        media_type="application/octet-stream",
        filename=f"dualtetrax_{version}.bin",
        headers={"X-MD5-Checksum": firmware.md5_checksum}
    )

# ─────────────────────────────────────────────────────────
# Device Endpoints
# ─────────────────────────────────────────────────────────

@app.post("/api/v1/devices/register")
async def register_device(request: DeviceRegisterRequest, db: Session = Depends(get_db)):
    """디바이스 등록"""
    device = Device(
        serial_number=request.serial_number,
        user_id=request.user_id,
        hw_version=request.hw_version,
        fw_version=request.fw_version
    )
    db.add(device)
    db.commit()
    return {"device_id": str(device.id)}

@app.put("/api/v1/devices/{device_id}/heartbeat")
async def device_heartbeat(device_id: str, request: HeartbeatRequest, db: Session = Depends(get_db)):
    """디바이스 상태 업데이트"""
    device = db.query(Device).filter(Device.id == device_id).first()
    if device:
        device.last_seen = datetime.now()
        device.fw_version = request.fw_version
        db.commit()
    return {"status": "ok"}

# ─────────────────────────────────────────────────────────
# User Endpoints
# ─────────────────────────────────────────────────────────

@app.post("/api/v1/auth/register")
async def register_user(request: UserRegisterRequest, db: Session = Depends(get_db)):
    """사용자 등록"""
    # ... password hashing, validation ...
    pass

@app.post("/api/v1/auth/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """로그인 (JWT 토큰 발급)"""
    # ... authentication logic ...
    pass
```

### 2.5 Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./certbot/conf:/etc/letsencrypt
    depends_on:
      - api

  api:
    build: ./api
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/dualtetrax
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - firmware_data:/data/firmware
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=dualtetrax
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  firmware_data:
  postgres_data:
```

### 2.6 Deployment Script

```bash
#!/bin/bash
# deploy.sh - Oracle Cloud VM에서 실행

# 1. Docker 설치
sudo apt update && sudo apt install -y docker.io docker-compose

# 2. 방화벽 설정
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT

# 3. Let's Encrypt SSL 인증서
sudo docker run -it --rm \
  -v ./certbot/conf:/etc/letsencrypt \
  certbot/certbot certonly --standalone \
  -d api.dualtetrax.com

# 4. 서비스 시작
docker-compose up -d
```

---

## 3. Stage 3: AWS Production

### 3.1 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │     S3       │    │ API Gateway  │    │   Lambda     │      │
│  │  (Firmware   │◄───│   (REST)     │◄───│  (Version    │      │
│  │   Storage)   │    │              │    │   Logic)     │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                   ▲                    │               │
│         │                   │                    │               │
│         │            ┌──────┴──────┐            │               │
│         │            │  DynamoDB   │◄───────────┘               │
│         │            │ (Metadata)  │                            │
│         │            └─────────────┘                            │
│         │                                                        │
└─────────┼────────────────────────────────────────────────────────┘
          │
          │ HTTPS (Pre-signed URL)
          ▼
┌─────────────────────┐
│    Mobile App       │
│  ┌───────────────┐  │
│  │ FW Repository │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────┴───────┐  │
│  │  OTA Service  │──┼──► BLE ──► Device
│  └───────────────┘  │
└─────────────────────┘
```

### 3.2 Components

| Component | Purpose |
|-----------|---------|
| S3 Bucket | 펌웨어 바이너리 저장 |
| API Gateway | REST API 엔드포인트 |
| Lambda | 비즈니스 로직 처리 |
| DynamoDB | 펌웨어 메타데이터 저장 |

---

## 2. S3 Bucket Structure

### 2.1 Bucket Layout

```
dualtetrax-firmware/
├── production/
│   ├── v1.0.0/
│   │   ├── dualtetrax_v1.0.0.bin
│   │   └── metadata.json
│   ├── v1.1.0/
│   │   ├── dualtetrax_v1.1.0.bin
│   │   └── metadata.json
│   └── latest.json
├── beta/
│   ├── v1.2.0-beta.1/
│   │   ├── dualtetrax_v1.2.0-beta.1.bin
│   │   └── metadata.json
│   └── latest.json
└── dev/
    └── ...
```

### 2.2 Metadata Schema (metadata.json)

```json
{
  "version": "1.1.0",
  "build_number": 110,
  "release_date": "2026-01-15T00:00:00Z",
  "file_name": "dualtetrax_v1.1.0.bin",
  "file_size": 1847296,
  "md5_checksum": "a1b2c3d4e5f6...",
  "sha256_checksum": "abcd1234...",
  "min_app_version": "1.0.0",
  "min_hw_version": "1.0",
  "release_notes": {
    "en": "Bug fixes and improvements",
    "ko": "버그 수정 및 개선"
  },
  "is_mandatory": false,
  "is_active": true
}
```

### 2.3 Latest Pointer (latest.json)

```json
{
  "version": "1.1.0",
  "path": "production/v1.1.0/dualtetrax_v1.1.0.bin"
}
```

---

## 3. DynamoDB Schema

### 3.1 Table: `dualtetrax-firmware`

| Attribute | Type | Description |
|-----------|------|-------------|
| `pk` (PK) | String | `FIRMWARE#<channel>` |
| `sk` (SK) | String | `VERSION#<version>` |
| `version` | String | Semantic version |
| `build_number` | Number | Build number |
| `s3_key` | String | S3 object key |
| `file_size` | Number | File size in bytes |
| `md5_checksum` | String | MD5 hash |
| `release_date` | String | ISO 8601 timestamp |
| `release_notes` | Map | Localized release notes |
| `min_app_version` | String | Minimum app version |
| `is_mandatory` | Boolean | Force update flag |
| `is_active` | Boolean | Available for download |
| `download_count` | Number | Download statistics |

### 3.2 GSI: `LatestVersion`

| Attribute | Type |
|-----------|------|
| `pk` (PK) | `FIRMWARE#<channel>` |
| `sk` (SK) | `build_number` (descending) |

---

## 4. API Design

### 4.1 Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/firmware/latest` | 최신 버전 정보 조회 |
| GET | `/firmware/versions` | 버전 목록 조회 |
| GET | `/firmware/{version}` | 특정 버전 정보 조회 |
| GET | `/firmware/{version}/download` | 다운로드 URL 생성 |
| POST | `/firmware/check-update` | 업데이트 확인 |

### 4.2 API: Check Update

**Request**
```http
POST /firmware/check-update
Content-Type: application/json

{
  "current_version": "1.0.0",
  "device_model": "DualTetraX",
  "hw_version": "1.0",
  "app_version": "1.0.0",
  "channel": "production"
}
```

**Response**
```json
{
  "update_available": true,
  "latest_version": "1.1.0",
  "is_mandatory": false,
  "file_size": 1847296,
  "release_notes": {
    "en": "Bug fixes and improvements",
    "ko": "버그 수정 및 개선"
  },
  "download_url": null
}
```

### 4.3 API: Get Download URL

**Request**
```http
GET /firmware/1.1.0/download?channel=production
```

**Response**
```json
{
  "version": "1.1.0",
  "download_url": "https://dualtetrax-firmware.s3.amazonaws.com/...",
  "expires_at": "2026-01-13T12:00:00Z",
  "file_size": 1847296,
  "md5_checksum": "a1b2c3d4e5f6..."
}
```

---

## 5. Lambda Functions

### 5.1 check-update

```python
# lambda/check_update.py

import boto3
import json
from semver import Version

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('dualtetrax-firmware')

def handler(event, context):
    body = json.loads(event['body'])
    current = Version.parse(body['current_version'])
    channel = body.get('channel', 'production')

    # Query latest active version
    response = table.query(
        KeyConditionExpression='pk = :pk',
        ExpressionAttributeValues={
            ':pk': f'FIRMWARE#{channel}'
        },
        ScanIndexForward=False,
        Limit=1
    )

    if not response['Items']:
        return {
            'statusCode': 200,
            'body': json.dumps({'update_available': False})
        }

    latest = response['Items'][0]
    latest_version = Version.parse(latest['version'])

    # Check if update is needed
    if latest_version > current:
        return {
            'statusCode': 200,
            'body': json.dumps({
                'update_available': True,
                'latest_version': latest['version'],
                'is_mandatory': latest.get('is_mandatory', False),
                'file_size': latest['file_size'],
                'release_notes': latest.get('release_notes', {})
            })
        }

    return {
        'statusCode': 200,
        'body': json.dumps({'update_available': False})
    }
```

### 5.2 get-download-url

```python
# lambda/get_download_url.py

import boto3
import json
from datetime import datetime, timedelta

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('dualtetrax-firmware')

BUCKET = 'dualtetrax-firmware'
URL_EXPIRY = 3600  # 1 hour

def handler(event, context):
    version = event['pathParameters']['version']
    channel = event['queryStringParameters'].get('channel', 'production')

    # Get firmware metadata
    response = table.get_item(
        Key={
            'pk': f'FIRMWARE#{channel}',
            'sk': f'VERSION#{version}'
        }
    )

    if 'Item' not in response:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Version not found'})
        }

    item = response['Item']

    # Generate pre-signed URL
    url = s3.generate_presigned_url(
        'get_object',
        Params={
            'Bucket': BUCKET,
            'Key': item['s3_key']
        },
        ExpiresIn=URL_EXPIRY
    )

    # Update download count
    table.update_item(
        Key={
            'pk': f'FIRMWARE#{channel}',
            'sk': f'VERSION#{version}'
        },
        UpdateExpression='ADD download_count :inc',
        ExpressionAttributeValues={':inc': 1}
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'version': version,
            'download_url': url,
            'expires_at': (datetime.utcnow() + timedelta(seconds=URL_EXPIRY)).isoformat() + 'Z',
            'file_size': item['file_size'],
            'md5_checksum': item['md5_checksum']
        })
    }
```

---

## 6. Mobile App Implementation

### 6.1 Firmware Repository

```dart
// lib/data/repositories/firmware_repository.dart

abstract class FirmwareRepository {
  Future<FirmwareUpdateInfo?> checkForUpdate(String currentVersion);
  Future<FirmwareDownload> downloadFirmware(String version);
  Stream<double> get downloadProgress;
}
```

### 6.2 Firmware API Service

```dart
// lib/data/datasources/firmware_api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class FirmwareApiService {
  final Dio _dio;
  static const String _baseUrl = 'https://api.dualtetrax.com/v1';

  FirmwareApiService() : _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get downloadProgress => _progressController.stream;

  Future<UpdateCheckResponse> checkForUpdate({
    required String currentVersion,
    required String deviceModel,
    String channel = 'production',
  }) async {
    final response = await _dio.post('/firmware/check-update', data: {
      'current_version': currentVersion,
      'device_model': deviceModel,
      'channel': channel,
    });

    return UpdateCheckResponse.fromJson(response.data);
  }

  Future<File> downloadFirmware(String version) async {
    // Get download URL
    final urlResponse = await _dio.get('/firmware/$version/download');
    final downloadUrl = urlResponse.data['download_url'];
    final expectedMd5 = urlResponse.data['md5_checksum'];

    // Download to temp file
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/firmware_$version.bin';

    await _dio.download(
      downloadUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          _progressController.add(received / total);
        }
      },
    );

    // Verify checksum
    final file = File(filePath);
    final actualMd5 = await _calculateMd5(file);

    if (actualMd5 != expectedMd5) {
      await file.delete();
      throw Exception('Firmware checksum verification failed');
    }

    return file;
  }

  Future<String> _calculateMd5(File file) async {
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }
}
```

### 6.3 Firmware Entities

```dart
// lib/domain/entities/firmware_info.dart

class FirmwareUpdateInfo {
  final bool updateAvailable;
  final String? latestVersion;
  final bool isMandatory;
  final int? fileSize;
  final Map<String, String>? releaseNotes;

  const FirmwareUpdateInfo({
    required this.updateAvailable,
    this.latestVersion,
    this.isMandatory = false,
    this.fileSize,
    this.releaseNotes,
  });
}

class FirmwareDownload {
  final String version;
  final File file;
  final int fileSize;
  final String md5Checksum;

  const FirmwareDownload({
    required this.version,
    required this.file,
    required this.fileSize,
    required this.md5Checksum,
  });
}
```

---

## 7. Service Page Integration

### 7.1 Service Page Structure

```
Service Page
├── Device Info Section
│   ├── Current Firmware Version
│   ├── Hardware Version
│   └── Serial Number
│
├── Firmware Update Section
│   ├── Check for Updates Button
│   ├── Update Available Banner (if new version)
│   │   ├── New Version: x.x.x
│   │   ├── Release Notes
│   │   └── Download & Install Button
│   └── Update Progress (during OTA)
│
├── Device Diagnostics Section
│   └── ...
│
└── Factory Reset Section
    └── ...
```

### 7.2 Update Flow

```
┌─────────────────┐
│  Service Page   │
│                 │
│ [Check Update]  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Check API Call  │────►│ No Update       │
└────────┬────────┘     │ "Up to date"    │
         │              └─────────────────┘
         ▼
┌─────────────────┐
│ Update Banner   │
│ v1.1.0 available│
│                 │
│ [Download]      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Download FW     │
│ Progress: 45%   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Confirm Install │
│                 │
│ [Start OTA]     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ BLE OTA Process │
│ (See design.md) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Success!        │
│ Device rebooting│
└─────────────────┘
```

---

## 8. Development/Test Mode (Local File)

서버 구축 전 또는 테스트 시 로컬 파일로 OTA 테스트가 가능합니다.

### 8.1 Local File Data Source

```dart
// lib/data/datasources/local_firmware_data_source.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';

class LocalFirmwareDataSource {

  /// 사용자가 .bin 파일 선택
  Future<FirmwareDownload?> pickFirmwareFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes!;

    // Validate ESP32 firmware header
    if (!_validateFirmwareHeader(bytes)) {
      throw Exception('Invalid firmware file: Not a valid ESP32 firmware');
    }

    // Calculate MD5
    final md5Checksum = md5.convert(bytes).toString();

    // Extract version from filename (e.g., dualtetrax_v1.2.0.bin)
    final version = _extractVersion(file.name) ?? 'unknown';

    return FirmwareDownload(
      version: version,
      bytes: Uint8List.fromList(bytes),
      fileSize: bytes.length,
      md5Checksum: md5Checksum,
      fileName: file.name,
    );
  }

  /// ESP32 펌웨어 헤더 검증 (Magic byte: 0xE9)
  bool _validateFirmwareHeader(List<int> bytes) {
    if (bytes.isEmpty) return false;
    return bytes[0] == 0xE9;  // ESP32 firmware magic byte
  }

  /// 파일명에서 버전 추출
  String? _extractVersion(String fileName) {
    // Pattern: dualtetrax_v1.2.0.bin or firmware_1.2.0.bin
    final regex = RegExp(r'v?(\d+\.\d+\.\d+)');
    final match = regex.firstMatch(fileName);
    return match?.group(1);
  }
}
```

### 8.2 Dev Mode Repository

```dart
// lib/data/repositories/firmware_repository_impl.dart

class FirmwareRepositoryImpl implements FirmwareRepository {
  final FirmwareApiService _apiService;
  final LocalFirmwareDataSource _localDataSource;
  final bool isDevelopmentMode;

  FirmwareRepositoryImpl({
    required FirmwareApiService apiService,
    required LocalFirmwareDataSource localDataSource,
    this.isDevelopmentMode = false,
  }) : _apiService = apiService,
       _localDataSource = localDataSource;

  @override
  Future<FirmwareDownload?> getFirmware() async {
    if (isDevelopmentMode) {
      // Dev mode: pick local file
      return _localDataSource.pickFirmwareFile();
    } else {
      // Production: download from server
      final updateInfo = await _apiService.checkForUpdate(...);
      if (updateInfo.updateAvailable) {
        return _apiService.downloadFirmware(updateInfo.latestVersion!);
      }
      return null;
    }
  }
}
```

### 8.3 Service Page Dev Mode UI

```dart
// Service Page with Dev Mode Toggle

class ServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... Device Info Section ...

        // Firmware Update Section
        _buildFirmwareSection(context),

        // Dev Mode Toggle (only in debug builds)
        if (kDebugMode) _buildDevModeToggle(context),
      ],
    );
  }

  Widget _buildDevModeToggle(BuildContext context) {
    return SwitchListTile(
      title: Text('Development Mode'),
      subtitle: Text('Select firmware from local file'),
      value: context.watch<OtaBloc>().state.isDevelopmentMode,
      onChanged: (value) {
        context.read<OtaBloc>().add(SetDevelopmentMode(value));
      },
    );
  }

  Widget _buildFirmwareSection(BuildContext context) {
    final state = context.watch<OtaBloc>().state;

    if (state.isDevelopmentMode) {
      return ElevatedButton.icon(
        icon: Icon(Icons.folder_open),
        label: Text('Select Firmware File (.bin)'),
        onPressed: () {
          context.read<OtaBloc>().add(SelectLocalFirmware());
        },
      );
    } else {
      return ElevatedButton.icon(
        icon: Icon(Icons.cloud_download),
        label: Text('Check for Updates'),
        onPressed: () {
          context.read<OtaBloc>().add(CheckForUpdates());
        },
      );
    }
  }
}
```

### 8.4 Development Mode Flow

```
┌─────────────────────────────────────────────────────────┐
│                    Service Page                          │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  [x] Development Mode                            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📁 Select Firmware File (.bin)                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   File Picker                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │  dualtetrax_v1.2.0.bin          1.8 MB          │   │
│  │  dualtetrax_v1.1.0.bin          1.7 MB          │   │
│  └─────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│               Firmware Selected                          │
│                                                          │
│  File: dualtetrax_v1.2.0.bin                            │
│  Size: 1,847,296 bytes                                   │
│  MD5:  a1b2c3d4e5f6...                                  │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │           🚀 Start OTA Update                    │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 8.5 Required Dependencies

```yaml
# pubspec.yaml
dependencies:
  file_picker: ^6.1.1
  crypto: ^3.0.3
```

### 8.6 iOS/Android Permissions

**iOS (Info.plist)**
```xml
<!-- For file access -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

**Android (AndroidManifest.xml)**
```xml
<!-- For file access (Android 10+) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32"/>
```

---

## 9. Security Considerations

### 9.1 S3 Security
- Bucket은 private, public access 차단
- Pre-signed URL로만 다운로드 허용
- URL 만료 시간: 1시간
- CloudFront 연동 고려 (CDN)

### 8.2 API Security
- API Key 또는 Cognito 인증
- Rate limiting (초당 10 요청)
- Request validation

### 8.3 Firmware Integrity
- MD5 + SHA256 체크섬
- (향후) 코드 서명 검증

---

## 9. Cost Estimation (AWS)

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| S3 | 100MB storage, 1000 downloads | ~$1 |
| API Gateway | 10,000 requests | ~$3 |
| Lambda | 10,000 invocations | ~$0 (Free tier) |
| DynamoDB | On-demand, low traffic | ~$1 |
| **Total** | | **~$5/month** |

---

## 10. Implementation Checklist

### AWS Infrastructure
- [ ] S3 버킷 생성 및 구조 설정
- [ ] DynamoDB 테이블 생성
- [ ] Lambda 함수 배포
- [ ] API Gateway 설정
- [ ] IAM 역할 및 정책 설정

### Mobile App
- [ ] FirmwareApiService 구현
- [ ] FirmwareRepository 구현
- [ ] Firmware BLoC 구현
- [ ] Service Page UI 구현

### DevOps
- [ ] CI/CD에서 펌웨어 자동 업로드
- [ ] 버전 관리 자동화
