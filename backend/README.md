# DualTetraX Backend API

Vercel Serverless Functions + Supabase

## 빠른 시작

### 1. 의존성 설치

```bash
cd backend
npm install
```

### 2. Supabase 프로젝트 생성

1. [Supabase](https://supabase.com) 접속
2. 새 프로젝트 생성: `qp-dualtetrax-dev`
3. 프로젝트 설정에서 다음 정보 복사:
   - Project URL
   - `anon` public key
   - `service_role` secret key

### 3. Upstash Redis 생성 (JWT 블랙리스트용)

1. [Upstash](https://upstash.com) 접속
2. 새 Redis 데이터베이스 생성
3. REST API 정보 복사:
   - UPSTASH_REDIS_REST_URL
   - UPSTASH_REDIS_REST_TOKEN

### 4. 환경 변수 설정

```bash
cp .env.example .env.local
```

`.env.local` 파일 수정:
```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
UPSTASH_REDIS_REST_URL=https://xxxxx.upstash.io
UPSTASH_REDIS_REST_TOKEN=AXxx...
```

### 5. Supabase 데이터베이스 스키마 적용

Supabase SQL Editor에서 `../doc/database_schema.md`의 SQL 스크립트 실행

### 6. 로컬 개발 서버 실행

```bash
npm run dev
```

서버가 `http://localhost:3000`에서 실행됩니다.

## API 엔드포인트

### 인증 (Authentication)

- `POST /api/auth/signup` - 회원가입
- `POST /api/auth/login` - 로그인
- `POST /api/auth/logout` - 로그아웃 (JWT 블랙리스트)

### 디바이스 (Devices)

- `POST /api/devices/register` - 디바이스 등록
- `GET /api/devices/list` - 내 디바이스 목록

### 헬스 체크

- `GET /api/health` - API 상태 확인

## 배포

### Vercel에 배포

```bash
# Vercel CLI 설치
npm i -g vercel

# 배포
vercel

# 프로덕션 배포
vercel --prod
```

### 환경 변수 설정 (Vercel)

Vercel 대시보드에서 환경 변수 추가:
1. Project Settings > Environment Variables
2. `.env.local`의 모든 변수 추가
3. 환경 선택: Production, Preview, Development

## 프로젝트 구조

```
backend/
├── api/                    # API 엔드포인트
│   ├── auth/
│   │   ├── signup.ts
│   │   ├── login.ts
│   │   └── logout.ts
│   ├── devices/
│   │   ├── register.ts
│   │   └── list.ts
│   └── health.ts
├── lib/                    # 라이브러리
│   ├── supabase.ts        # Supabase 클라이언트
│   └── validation.ts      # Zod 스키마
├── .env.example           # 환경 변수 템플릿
├── package.json
├── tsconfig.json
└── vercel.json            # Vercel 설정
```

## 코드 스타일

- 띄어쓰기: 2칸
- 주석: 영어로 (최소화)
- 네이밍: camelCase (변수/함수), PascalCase (클래스)
- if문: 항상 {} 사용

## 보안

- ✅ JWT 블랙리스트 (로그아웃 시 토큰 무효화)
- ✅ Row Level Security (RLS) - Supabase
- ✅ 입력 검증 (Zod 스키마)
- ✅ HTTPS 전용
- ⏳ Rate Limiting (추후 구현)

## 테스트

```bash
npm test
```

## 문서

- [API 명세](../doc/api_specification.md)
- [데이터베이스 스키마](../doc/database_schema.md)
- [보안 설계](../doc/security_privacy_design.md)
