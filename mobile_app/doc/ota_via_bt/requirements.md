# BLE OTA Requirements Specification

## Document Info
- **Version**: 1.0
- **Date**: 2026-01-13
- **Project**: DualTetraX Mobile App - BLE OTA Feature

---

## 1. Overview

### 1.1 Purpose
DualTetraX 디바이스의 펌웨어를 Bluetooth Low Energy(BLE)를 통해 무선으로 업데이트하는 기능을 구현한다.

### 1.2 Background
현재 시스템은 WiFi 기반 OTA만 지원한다. BLE OTA를 추가하면:
- WiFi AP 연결 없이 펌웨어 업데이트 가능
- 모바일 앱에서 직접 업데이트 수행
- 사용자 편의성 향상

### 1.3 Scope
| In Scope | Out of Scope |
|----------|--------------|
| BLE를 통한 펌웨어 전송 | WiFi OTA 수정 |
| 업데이트 진행률 표시 | 펌웨어 서명 검증 (Phase 2) |
| 오류 처리 및 복구 | 다중 디바이스 동시 업데이트 |
| 배터리 안전 검사 | 백그라운드 업데이트 |

---

## 2. Functional Requirements

### 2.1 OTA 시작 조건 (FR-001)
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001-1 | BLE 연결 상태에서만 OTA 시작 가능 | Must |
| FR-001-2 | 디바이스 배터리 70% 이상에서만 OTA 시작 | Must |
| FR-001-3 | 디바이스가 Standby 또는 Idle 상태에서만 OTA 가능 | Must |
| FR-001-4 | 진행 중인 Shot 세션이 없어야 함 | Must |

### 2.2 펌웨어 파일 처리 (FR-002)
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-002-1 | .bin 파일 형식 지원 | Must |
| FR-002-2 | 최대 2MB 펌웨어 파일 지원 | Must |
| FR-002-3 | 펌웨어 헤더 검증 (ESP32 magic byte 0xE9) | Must |
| FR-002-4 | MD5 체크섬 검증 | Must |
| FR-002-5 | 파일 선택 UI 제공 | Must |

### 2.3 펌웨어 전송 (FR-003)
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-003-1 | 펌웨어를 청크 단위로 분할 전송 (512 bytes) | Must |
| FR-003-2 | 각 청크 전송 후 ACK 수신 확인 | Must |
| FR-003-3 | 전송 실패 시 재시도 (최대 3회) | Must |
| FR-003-4 | 전체 진행률 실시간 표시 | Must |
| FR-003-5 | 예상 남은 시간 표시 | Should |

### 2.4 OTA 상태 관리 (FR-004)
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-004-1 | OTA 상태 변경 실시간 알림 | Must |
| FR-004-2 | 지원 상태: IDLE, DOWNLOADING, VALIDATING, UPGRADING, SUCCESS, ERROR | Must |
| FR-004-3 | 에러 코드 및 메시지 표시 | Must |
| FR-004-4 | 성공 시 디바이스 자동 재부팅 안내 | Must |

### 2.5 취소 및 복구 (FR-005)
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-005-1 | 사용자가 언제든지 OTA 취소 가능 | Must |
| FR-005-2 | BLE 연결 끊김 시 자동 OTA 취소 | Must |
| FR-005-3 | 취소 후 디바이스 정상 상태 복귀 | Must |
| FR-005-4 | 실패한 펌웨어는 롤백 (기존 펌웨어 유지) | Must |

### 2.6 사용자 인터페이스 (FR-006)
| ID | Requirement | Priority |
|----|-------------|----------|
| FR-006-1 | OTA 전용 화면/모달 제공 | Must |
| FR-006-2 | 진행률 프로그레스 바 표시 | Must |
| FR-006-3 | 현재 상태 텍스트 표시 | Must |
| FR-006-4 | 취소 버튼 제공 | Must |
| FR-006-5 | 완료/실패 결과 화면 | Must |
| FR-006-6 | 다국어 지원 (최소 한국어, 영어) | Should |

---

## 3. Non-Functional Requirements

### 3.1 Performance (NFR-001)
| ID | Requirement | Target |
|----|-------------|--------|
| NFR-001-1 | 2MB 펌웨어 전송 시간 | < 60초 |
| NFR-001-2 | BLE MTU 협상 | 최소 247 bytes |
| NFR-001-3 | 청크 전송 throughput | > 30 KB/s |

### 3.2 Reliability (NFR-002)
| ID | Requirement | Target |
|----|-------------|--------|
| NFR-002-1 | OTA 성공률 | > 95% |
| NFR-002-2 | 청크 재전송 성공률 | > 99% |
| NFR-002-3 | 연결 끊김 복구 | 5초 이내 감지 |

### 3.3 Safety (NFR-003)
| ID | Requirement | Target |
|----|-------------|--------|
| NFR-003-1 | OTA 중 배터리 소모 체크 | 50% 이하 시 중단 |
| NFR-003-2 | 잘못된 펌웨어 방지 | 헤더 + MD5 검증 |
| NFR-003-3 | Brick 방지 | 롤백 메커니즘 |

### 3.4 Usability (NFR-004)
| ID | Requirement | Target |
|----|-------------|--------|
| NFR-004-1 | OTA 시작까지 탭 수 | < 3회 |
| NFR-004-2 | 진행 상황 업데이트 주기 | 1초 이내 |
| NFR-004-3 | 에러 메시지 이해도 | 사용자 친화적 텍스트 |

---

## 4. Constraints

### 4.1 기술적 제약
- **BLE MTU**: iOS 기본 185 bytes, Android 기본 23 bytes (협상 필요)
- **BLE 대역폭**: WiFi 대비 낮음 (~100-500 KB/s)
- **ESP32 Flash**: OTA 파티션 2MB 제한
- **연결 안정성**: BLE는 WiFi보다 연결 끊김 가능성 높음

### 4.2 호환성 제약
- **iOS**: 13.0 이상
- **Android**: 6.0 (API 23) 이상
- **펌웨어**: ESP-IDF v5.3.4 기반

### 4.3 기존 시스템 제약
- WiFi OTA 기능 유지 필수
- 기존 BLE 상태 서비스와 공존
- NVS OTA 로그 시스템 활용

---

## 5. Dependencies

### 5.1 Firmware Dependencies
| Component | Version | Purpose |
|-----------|---------|---------|
| ESP-IDF | v5.3.4 | OTA API, NimBLE |
| NimBLE | 2.x | BLE GATT Server |
| DTOtaManager | existing | OTA core logic |

### 5.2 Mobile App Dependencies
| Component | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.38+ | Framework |
| flutter_blue_plus | ^1.32.0 | BLE communication |
| file_picker | ^6.0.0 | Firmware file selection |

---

## 6. Acceptance Criteria

### 6.1 Must Pass
- [ ] BLE 연결 상태에서 OTA 시작 가능
- [ ] 2MB 펌웨어 파일 60초 이내 전송 완료
- [ ] 진행률 실시간 표시 (1초 이내 업데이트)
- [ ] OTA 성공 후 디바이스 자동 재부팅
- [ ] OTA 실패 시 기존 펌웨어로 롤백
- [ ] 사용자 취소 기능 동작
- [ ] 배터리 70% 미만 시 OTA 거부

### 6.2 Should Pass
- [ ] 예상 남은 시간 표시
- [ ] 다국어 지원 (한국어, 영어)
- [ ] OTA 히스토리 로깅

---

## 7. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| BLE 연결 끊김 | High | Medium | 재연결 로직, 자동 취소 |
| 펌웨어 손상 | Critical | Low | MD5 검증, 롤백 |
| 배터리 부족 | High | Medium | 시작/진행 중 배터리 체크 |
| 느린 전송 속도 | Medium | High | MTU 협상 최적화, 청크 크기 조정 |
| 앱 백그라운드 전환 | High | Medium | 포그라운드 서비스 사용 |

---

## 8. References

- ESP-IDF OTA Documentation
- NimBLE GATT Server API
- flutter_blue_plus Package Documentation
- DualTetraX WiFi OTA Implementation (`/modules/ota_manager/`)
