# DualTetraX Cloud Services

DualTetraX 뷰티 디바이스 클라우드 플랫폼 — Backend API + Frontend Web

## 접속 방법

| 서비스 | URL |
|--------|-----|
| **Frontend (웹)** | https://frontend-seven-gamma-56.vercel.app |
| **Backend API** | https://qp-dualtetrax-api.vercel.app |

### 사용자 접속

1. https://frontend-seven-gamma-56.vercel.app 접속
2. **Sign Up** 으로 회원가입 (이메일 + 비밀번호)
3. Supabase에서 이메일 확인 후 로그인
4. Dashboard, Devices, Stats 등 사용

### 관리자 접속

관리자 계정 최초 생성 (1회만):

```bash
# 1. Vercel 대시보드에서 ADMIN_SETUP_KEY 환경변수 설정
#    Project: qp-dualtetrax-api → Settings → Environment Variables
#    Key: ADMIN_SETUP_KEY
#    Value: (원하는 비밀키)

# 2. 먼저 일반 계정으로 가입 후, setup 엔드포인트 호출
curl -X POST https://qp-dualtetrax-api.vercel.app/api/admin/setup \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "setup_key": "YOUR_ADMIN_SETUP_KEY"}'
```

이후 기존 관리자가 다른 사용자를 승격:

```bash
curl -X POST https://qp-dualtetrax-api.vercel.app/api/admin/promote \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{"email": "newadmin@example.com"}'
```

관리자 로그인 후 `/admin` 경로에서 관리 페이지 접근 가능.

### API 헬스체크

```bash
curl https://qp-dualtetrax-api.vercel.app/api/ping
# → {"pong":true}

curl https://qp-dualtetrax-api.vercel.app/api/health
# → {"healthy":true, ...}
```

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| Backend | Vercel Serverless Functions (Node.js + TypeScript) |
| Frontend | Next.js 14 (App Router) + Tailwind CSS |
| Database | Supabase (PostgreSQL + RLS) |
| Auth | Supabase Auth (Email/Password) |
| Cache | Upstash Redis (Rate Limiting + Token Blacklist) |
| i18n | Custom React Context (ko/en/zh/th/ja/pt) |

## 프로젝트 구조

```
services/
├── backend/            # Vercel Serverless API
│   ├── api/            # 10 handler files (Hobby plan limit: 12)
│   │   ├── ping.ts
│   │   ├── health.ts
│   │   ├── auth/logout.ts
│   │   ├── devices.ts      # /api/devices, /api/devices/:id, /api/devices/:id/transfer
│   │   ├── sessions.ts     # /api/sessions, /api/sessions/upload, /api/sessions/export
│   │   ├── stats.ts        # /api/stats/daily, /api/stats/range
│   │   ├── user.ts         # /api/profile, /api/notifications, /api/skin-profile, /api/consent
│   │   ├── goals.ts        # /api/goals, /api/goals/:id
│   │   ├── firmware.ts     # /api/firmware/latest, /api/firmware/check
│   │   └── admin.ts        # /api/admin/* (모든 관리자 라우트)
│   ├── lib/            # Shared libraries
│   │   ├── auth.ts         # authenticate, authenticateAdmin
│   │   ├── supabase.ts     # supabaseAdmin, createUserClient
│   │   ├── ratelimit.ts    # rate limiting (Upstash)
│   │   ├── validate.ts     # Zod schemas
│   │   └── audit.ts        # logAdminAction
│   └── vercel.json     # 26 rewrite rules + CORS headers
│
├── frontend/           # Next.js 14 Web App
│   └── src/
│       ├── app/        # 23 pages
│       │   ├── page.tsx            # Landing
│       │   ├── login/              # 로그인
│       │   ├── signup/             # 회원가입
│       │   ├── reset-password/     # 비밀번호 재설정
│       │   ├── dashboard/          # 대시보드
│       │   ├── devices/            # 디바이스 관리
│       │   ├── stats/              # 사용 통계
│       │   ├── profile/            # 프로필
│       │   ├── settings/           # 알림 설정
│       │   ├── skin-profile/       # 피부 프로필
│       │   ├── goals/              # 사용 목표
│       │   ├── consent/            # 동의 관리
│       │   ├── sessions/export/    # CSV 내보내기
│       │   └── admin/              # 관리자 (8 pages)
│       ├── components/     # Navbar, AdminNavbar, LanguageSwitcher, etc.
│       ├── i18n/           # 다국어 (6개 언어)
│       │   ├── context.tsx         # LocaleProvider, useT()
│       │   └── messages/           # en, ko, zh, th, ja, pt
│       └── lib/            # api.ts, supabase client
│
└── doc/                # 설계 문서
```

---

## 배포 방법

### 사전 요구사항

- Node.js 18+
- Vercel CLI (`npm i -g vercel`)
- Vercel 계정 + 프로젝트 연결 완료

### 환경변수 (Vercel 대시보드에서 설정)

**Backend** (qp-dualtetrax-api):
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_JWT_SECRET=xxx
UPSTASH_REDIS_REST_URL=https://xxx.upstash.io
UPSTASH_REDIS_REST_TOKEN=xxx
ADMIN_SETUP_KEY=xxx          # 관리자 초기 설정용 (선택)
```

**Frontend** (frontend):
```
NEXT_PUBLIC_API_URL=https://qp-dualtetrax-api.vercel.app
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

### Backend 배포

```bash
cd services/backend
vercel --prod
```

10개 Serverless Function으로 빌드됨 (Hobby plan limit: 12).

### Frontend 배포

```bash
cd services/frontend
vercel --prod
```

23개 페이지 + 정적 자산 빌드됨.

### 로컬 개발

```bash
# Backend
cd services/backend
npm install
vercel dev          # http://localhost:3000

# Frontend (별도 터미널)
cd services/frontend
npm install
npm run dev         # http://localhost:3001
```

`.env.local` 파일에 환경변수를 설정해야 함.

---

## 다국어 지원

6개 언어 지원: 한국어(기본), English, 中文, ไทย, 日本語, Português

- 언어 전환: 상단 네비게이션 바의 언어 선택 드롭다운
- 설정 저장: localStorage에 자동 저장
- 번역 파일: `frontend/src/i18n/messages/` 디렉토리

---

## API 라우트 목록

### User API

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/logout | 로그아웃 |
| GET/PUT | /api/profile | 프로필 조회/수정 |
| GET/PUT | /api/notifications | 알림 설정 |
| GET/PUT | /api/skin-profile | 피부 프로필 |
| GET/POST | /api/consent | 동의 관리 |
| GET | /api/devices | 디바이스 목록 |
| POST | /api/devices | 디바이스 등록 |
| GET/PUT/DELETE | /api/devices/:id | 디바이스 상세 |
| POST | /api/devices/:id/transfer | 소유권 이전 |
| GET | /api/sessions | 세션 목록 |
| POST | /api/sessions/upload | 세션 업로드 |
| GET | /api/sessions/export | CSV 내보내기 |
| DELETE | /api/sessions/:id | 세션 삭제 |
| GET/POST | /api/goals | 목표 관리 |
| PUT/DELETE | /api/goals/:id | 목표 수정/삭제 |
| GET | /api/stats/daily | 일별 통계 |
| GET | /api/stats/range | 기간별 통계 |
| GET | /api/firmware/latest | 최신 펌웨어 |
| GET | /api/firmware/check | OTA 업데이트 확인 |

### Admin API

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/admin/setup | 최초 관리자 생성 |
| POST | /api/admin/promote | 사용자 관리자 승격 |
| GET | /api/admin/stats | 대시보드 통계 |
| GET | /api/admin/users | 사용자 목록 |
| GET/PUT | /api/admin/users/:id | 사용자 상세/수정 |
| GET | /api/admin/devices | 디바이스 목록 |
| GET | /api/admin/logs | 감사 로그 |
| GET/POST | /api/admin/announcements | 공지사항 |
| PUT/DELETE | /api/admin/announcements/:id | 공지 수정/삭제 |
| GET/POST | /api/admin/firmware | 펌웨어 버전 |
| GET/POST | /api/admin/firmware/rollouts | 롤아웃 관리 |
| PUT | /api/admin/firmware/rollouts/:id | 롤아웃 수정 |
