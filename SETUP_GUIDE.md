# DualTetraX Services - 로컬 개발 환경 설정 가이드

**소요 시간**: 약 15분

---

## 1단계: Supabase 프로젝트 생성 (5분)

### 1.1 계정 생성 및 프로젝트 생성

1. **Supabase 접속**
   ```
   https://supabase.com
   ```

2. **Sign up / Login**
   - GitHub 계정으로 로그인 (권장)
   - 또는 이메일로 가입

3. **새 프로젝트 생성**
   - "New Project" 클릭
   - 프로젝트 정보 입력:
     ```
     Name: qp-dualtetrax-dev
     Database Password: [강력한 비밀번호 생성 - 메모장에 저장!]
     Region: Northeast Asia (Seoul) - 한국 선택
     Pricing Plan: Free
     ```
   - "Create new project" 클릭
   - ⏳ 프로젝트 생성 대기 (약 2분)

### 1.2 API Keys 복사

프로젝트 생성 완료 후:

1. **Settings** (왼쪽 메뉴 하단) → **API** 클릭

2. **다음 정보를 메모장에 복사**:
   ```
   Project URL: https://xxxxxxxxxxxxx.supabase.co

   anon public (공개 키):
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZi...

   service_role (비밀 키 - 절대 노출 금지!):
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZi...
   ```

---

## 2단계: 데이터베이스 스키마 적용 (3분)

### 2.1 SQL Editor 열기

1. Supabase 대시보드에서 **SQL Editor** (왼쪽 메뉴) 클릭
2. "New query" 클릭

### 2.2 스키마 SQL 실행

1. 다음 파일 열기:
   ```
   services/doc/database_schema.md
   ```

2. 파일 내용에서 SQL 스크립트 부분만 복사 (주석 제외):
   - `CREATE TABLE users ...` 부터
   - 마지막 `ALTER TABLE` 까지

3. SQL Editor에 붙여넣기

4. **RUN** 버튼 클릭 (또는 Cmd/Ctrl + Enter)

5. ✅ "Success. No rows returned" 메시지 확인

### 2.3 테이블 생성 확인

1. **Table Editor** (왼쪽 메뉴) 클릭
2. 다음 테이블들이 생성되었는지 확인:
   - `users`
   - `devices`
   - `usage_sessions`
   - `device_states`
   - `firmware_versions`
   - `notifications`
   - `analysts`
   - `analyst_export_logs`

---

## 3단계: Upstash Redis 생성 (3분)

### 3.1 계정 생성 및 데이터베이스 생성

1. **Upstash 접속**
   ```
   https://console.upstash.com
   ```

2. **Sign up / Login**
   - Email 또는 GitHub 계정으로 로그인

3. **Redis 데이터베이스 생성**
   - "Create Database" 클릭
   - 설정:
     ```
     Name: dualtetrax-jwt-blacklist
     Type: Regional
     Region: ap-northeast-2 (Seoul) - 한국 선택
     Eviction: Enable (자동 메모리 정리)
     ```
   - "Create" 클릭

### 3.2 REST API 정보 복사

데이터베이스 생성 후:

1. 데이터베이스 상세 페이지에서 **REST API** 탭 클릭

2. **다음 정보를 메모장에 복사**:
   ```
   UPSTASH_REDIS_REST_URL: https://xxxxxxx-xxxxx.upstash.io

   UPSTASH_REDIS_REST_TOKEN: AXxxxxxxxxxxxxxxxxxxxxxxxx
   ```

---

## 4단계: Backend 환경 변수 설정 (2분)

### 4.1 .env.local 파일 생성

```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services/backend
cp .env.example .env.local
```

### 4.2 .env.local 파일 수정

파일을 열어서 다음 값들을 입력:

```bash
# Supabase Configuration
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZi...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZi...

# Environment
NODE_ENV=development

# API Configuration
API_BASE_URL=http://localhost:3000

# Upstash Redis (for JWT blacklist)
UPSTASH_REDIS_REST_URL=https://xxxxxxx-xxxxx.upstash.io
UPSTASH_REDIS_REST_TOKEN=AXxxxxxxxxxxxxxxxxxxxxxxxx

# Kakao OAuth (선택 - 나중에 설정)
# KAKAO_REST_API_KEY=your-kakao-rest-api-key
# KAKAO_REDIRECT_URI=http://localhost:3000/api/auth/kakao/callback

# Naver OAuth (선택 - 나중에 설정)
# NAVER_CLIENT_ID=your-naver-client-id
# NAVER_CLIENT_SECRET=your-naver-client-secret
# NAVER_REDIRECT_URI=http://localhost:3000/api/auth/naver/callback
```

**⚠️ 주의**:
- `xxxxxxxxxxxxx` 부분을 1단계와 3단계에서 복사한 실제 값으로 교체
- `service_role` 키는 절대 GitHub에 커밋하지 말 것!

---

## 5단계: Frontend 환경 변수 설정 (1분)

### 5.1 .env.local 파일 생성

```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services/frontend
cp .env.example .env.local
```

### 5.2 .env.local 파일 수정

```bash
# Supabase Configuration (Public - Frontend)
NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZi...

# Backend API URL
NEXT_PUBLIC_API_URL=http://localhost:3000

# Environment
NODE_ENV=development
```

**⚠️ 주의**:
- Frontend는 `anon public` 키만 사용 (service_role 키 사용 금지!)
- `NEXT_PUBLIC_` 접두사가 있는 변수만 브라우저에 노출됨

---

## 6단계: Backend 실행 (1분)

### 6.1 의존성 설치 및 실행

```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services/backend

# 의존성 설치
npm install

# 개발 서버 실행
npm run dev
```

### 6.2 동작 확인

브라우저에서 접속:
```
http://localhost:3000/api/health
```

**예상 결과**:
```json
{
  "status": "ok",
  "timestamp": "2026-02-08T12:34:56.789Z"
}
```

✅ 위 메시지가 보이면 Backend가 정상 동작하는 것입니다!

---

## 7단계: Frontend 실행 (1분)

### 7.1 새 터미널 열기

Backend는 실행 상태로 두고, **새 터미널**을 엽니다.

### 7.2 의존성 설치 및 실행

```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services/frontend

# 의존성 설치
npm install

# 개발 서버 실행
npm run dev
```

### 7.3 동작 확인

브라우저에서 접속:
```
http://localhost:3001
```

✅ DualTetraX 랜딩 페이지가 보이면 성공!

---

## 8단계: 통합 테스트 (5분)

### 8.1 회원가입 테스트

1. **Frontend 접속**:
   ```
   http://localhost:3001
   ```

2. **"회원가입" 버튼** 클릭

3. **정보 입력**:
   ```
   이메일: test@example.com
   비밀번호: Test1234!@#
   비밀번호 확인: Test1234!@#
   ```

4. **"회원가입" 클릭**

5. ✅ "회원가입이 완료되었습니다! 이메일을 확인해주세요." 메시지 확인

### 8.2 이메일 확인 (Supabase)

**중요**: Supabase 무료 플랜은 실제 이메일을 보내지 않습니다. 대신:

1. Supabase 대시보드 → **Authentication** → **Users** 클릭

2. 방금 가입한 사용자 확인:
   ```
   Email: test@example.com
   Confirmed: false (아직 확인 안됨)
   ```

3. **수동으로 확인 처리**:
   - 사용자 행 클릭
   - "Confirm email" 버튼 클릭
   - 또는: 사용자 삭제 후 재가입 시 자동 확인 설정

**개발 환경 우회 방법**:
```bash
# Supabase 대시보드 → Settings → Auth → Email Auth
# "Confirm email" 옵션을 OFF로 설정 (개발 전용!)
```

### 8.3 로그인 테스트

1. **로그인 페이지** 접속:
   ```
   http://localhost:3001/login
   ```

2. **정보 입력**:
   ```
   이메일: test@example.com
   비밀번호: Test1234!@#
   ```

3. **"로그인" 클릭**

4. ✅ 대시보드로 리다이렉트 확인:
   ```
   http://localhost:3001/dashboard
   ```

### 8.4 디바이스 등록 테스트

1. **대시보드**에서 **"+ 디바이스 등록"** 버튼 클릭

2. **정보 입력**:
   ```
   시리얼 번호: DTX-20260208-001
   모델명: DualTetraX-01
   펌웨어 버전: v1.0.23
   BLE MAC 주소: AA:BB:CC:DD:EE:FF (선택)
   ```

3. **"디바이스 등록" 클릭**

4. ✅ "디바이스가 성공적으로 등록되었습니다!" 메시지 확인

5. ✅ 대시보드에 디바이스 카드 표시 확인

### 8.5 로그아웃 테스트

1. **대시보드** 우측 상단 **"로그아웃"** 클릭

2. ✅ 로그인 페이지로 리다이렉트 확인

3. ✅ JWT 토큰이 Redis 블랙리스트에 추가됨 (Backend 로그 확인)

---

## 9단계: 데이터베이스 확인 (선택)

### 9.1 Supabase Table Editor에서 확인

1. **Supabase 대시보드** → **Table Editor**

2. **`devices` 테이블** 클릭

3. ✅ 방금 등록한 디바이스 데이터 확인:
   ```
   id: (UUID)
   user_id: (UUID - 사용자 ID)
   serial_number: DTX-20260208-001
   model_name: DualTetraX-01
   firmware_version: v1.0.23
   ble_mac_address: AA:BB:CC:DD:EE:FF
   is_active: true
   registered_at: 2026-02-08 12:34:56
   ```

### 9.2 Upstash Redis 확인 (로그아웃 후)

1. **Upstash Console** → 데이터베이스 클릭

2. **Data Browser** 탭 클릭

3. ✅ 블랙리스트 키 확인:
   ```
   Key: blacklist:eyJhbGci...
   Value: 1
   TTL: 3600 (1시간)
   ```

---

## 🎉 축하합니다!

**DualTetraX Services MVP가 로컬에서 정상 동작합니다!**

### ✅ 완료된 기능
- 회원가입 / 로그인 / 로그아웃
- JWT 블랙리스트 (Redis)
- 디바이스 등록 / 목록 조회
- 대시보드

### 🚀 다음 단계
- **Vercel 배포** (프로덕션 환경)
- **모바일 앱 통합** (Flutter)
- **관리자 콘솔** 구현
- **사용 통계 수집** 구현

---

## ❓ 문제 해결

### Backend 실행 오류

**오류**: `Error: SUPABASE_URL is not defined`
**해결**: `.env.local` 파일이 제대로 생성되었는지 확인

**오류**: `EADDRINUSE: address already in use :::3000`
**해결**:
```bash
# 포트 3000을 사용하는 프로세스 종료
lsof -ti:3000 | xargs kill -9

# 또는 다른 포트 사용
PORT=3001 npm run dev
```

### Frontend 실행 오류

**오류**: `Failed to fetch`
**해결**: Backend가 실행 중인지 확인 (`http://localhost:3000/api/health`)

**오류**: `Invalid Supabase URL`
**해결**: `.env.local`의 `NEXT_PUBLIC_SUPABASE_URL` 확인

### 로그인 실패

**문제**: "Invalid email or password"
**해결**:
1. Supabase → Authentication → Users에서 이메일 확인 상태 확인
2. "Confirm email" 클릭 또는 이메일 확인 설정 OFF

### 디바이스 등록 실패

**문제**: "이미 등록된 시리얼 번호입니다"
**해결**:
1. Supabase Table Editor → `devices` 테이블에서 해당 시리얼 번호 삭제
2. 또는 다른 시리얼 번호 사용 (예: `DTX-20260208-002`)

---

## 📞 지원

문제가 계속되면 다음 정보를 포함하여 문의:
1. 오류 메시지 (스크린샷)
2. Browser Console 로그 (F12 → Console)
3. Backend 터미널 로그
4. `.env.local` 파일 내용 (키 값은 제외하고 변수명만)
