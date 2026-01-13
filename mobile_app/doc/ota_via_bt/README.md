# BLE OTA Documentation

## Overview

DualTetraX 디바이스의 Bluetooth Low Energy(BLE)를 통한 OTA(Over-The-Air) 펌웨어 업데이트 기능 설계 문서입니다.

## Documents

| Document | Description |
|----------|-------------|
| [requirements.md](requirements.md) | 기능/비기능 요구사항 정의 |
| [design.md](design.md) | BLE OTA 기술 설계 |
| [firmware_management.md](firmware_management.md) | 펌웨어 관리 (서버 + 로컬) |

## Quick Summary

### Key Features
- BLE GATT 기반 펌웨어 전송
- 실시간 진행률 표시
- 배터리 안전 검사 (70% 이상)
- 오류 시 자동 롤백
- 기존 WiFi OTA와 공존

### Deployment Stages
| Stage | Infrastructure | Use Case |
|-------|----------------|----------|
| **1. Local** | 모바일 앱 단독 (파일 선택) | 개발/OTA 테스트 |
| **2. MVP** | Oracle Cloud (단일 VM) | 초기 서비스 운영 |
| **3. Production** | AWS (완전 관리형) | 상용 서비스 |

### BLE Service UUID
```
OTA Service: 12341111-1234-1234-1234-123456789abc
```

### Performance Targets
- 2MB 펌웨어: < 60초
- 청크 크기: 240 bytes
- Throughput: > 30 KB/s

## Implementation Checklist

### Stage 1: Local (개발/테스트)
- [ ] Firmware: `dt_ble_ota_service.hpp/cpp` 생성
- [ ] Firmware: GATT 서비스 등록
- [ ] Firmware: DTOtaManager 연동
- [ ] App: `ble_ota_data_source.dart` 생성
- [ ] App: `local_firmware_data_source.dart` 생성
- [ ] App: OTA BLoC 구현
- [ ] App: Service Page UI 구현

### Stage 2: Oracle Cloud MVP
- [ ] Server: FastAPI + PostgreSQL 구축
- [ ] Server: Docker Compose 배포
- [ ] Server: SSL 인증서 설정
- [ ] App: Server API 연동

### Stage 3: AWS Production
- [ ] AWS: S3 + API Gateway + Lambda 구축
- [ ] AWS: DynamoDB 테이블 생성
- [ ] App: AWS API 연동

## Architecture Diagram

```
Mobile App                    Firmware
┌─────────────┐              ┌─────────────┐
│   OTA UI    │              │ BLE OTA Svc │
│      │      │              │      │      │
│   OTA BLoC  │◄── BLE ────►│ DTOtaManager│
│      │      │              │      │      │
│ BLE DataSrc │              │ OTA Partition│
└─────────────┘              └─────────────┘
```

## Status
- **Created**: 2026-01-13
- **Status**: Design Phase
