# DualTetraX Services - Vercel 배포 가이드

## 🚀 배포 개요

**Dev 환경**:
- Backend API: `qp-dualtetrax-dev-api`
- Frontend Web: `qp-dualtetrax-dev-web`

**Prod 환경** (향후):
- Backend API: `qp-dualtetrax-prod-api`
- Frontend Web: `qp-dualtetrax-prod-web`

---

## 📋 사전 준비

### 1. Vercel CLI 설치
```bash
npm install -g vercel
```

### 2. Vercel 로그인
```bash
vercel login
```

---

## 🔧 Backend API 배포 (Dev)

### 1. Backend 디렉토리로 이동
```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services/backend
```

### 2. 첫 배포 (프로젝트 생성)
```bash
vercel --prod
```

**프로젝트 설정 시**:
- **Project Name**: `qp-dualtetrax-dev-api`
- **Framework**: `Other`
- **Root Directory**: `./` (현재 디렉토리)
- **Build Command**: `npm run type-check`
- **Output Directory**: (비워두기)
- **Environment**: `Production`

### 3. 환경 변수 설정

Vercel 대시보드에서 수동으로 설정:

```
SUPABASE_URL=https://jivpguvyrrazbdczlfyg.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
UPSTASH_REDIS_REST_URL=https://brave-poodle-38416.upstash.io
UPSTASH_REDIS_REST_TOKEN=AZYQAAIncDI3MjQ5ZDM2OGI2Yjc0NTlkODkxZjdhYTk3NjkyYWMxN3AyMzg0MTY
NODE_ENV=production
```

**또는 CLI로 설정**:
```bash
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add UPSTASH_REDIS_REST_URL
vercel env add UPSTASH_REDIS_REST_TOKEN
vercel env add NODE_ENV
```

### 4. 재배포 (환경 변수 적용)
```bash
vercel --prod
```

### 5. API 테스트
```bash
curl https://qp-dualtetrax-dev-api.vercel.app/api/health
```

**예상 응답**:
```json
{
  "status": "ok",
  "timestamp": "2026-02-08T...",
  "environment": "production",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

---

## 🌐 Frontend Web 배포 (Dev)

### 1. Frontend 디렉토리로 이동
```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services/frontend
```

### 2. 환경 변수 파일 업데이트

`.env.production` 생성 (Backend 배포 후 URL 확인):
```bash
NEXT_PUBLIC_SUPABASE_URL=https://jivpguvyrrazbdczlfyg.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
NEXT_PUBLIC_API_URL=https://qp-dualtetrax-dev-api.vercel.app
NODE_ENV=production
```

### 3. 첫 배포
```bash
vercel --prod
```

**프로젝트 설정 시**:
- **Project Name**: `qp-dualtetrax-dev-web`
- **Framework**: `Next.js`
- **Root Directory**: `./`
- **Build Command**: `npm run build`
- **Output Directory**: `.next`
- **Environment**: `Production`

### 4. 환경 변수 설정

Vercel 대시보드 또는 CLI:
```bash
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
vercel env add NEXT_PUBLIC_API_URL
vercel env add NODE_ENV
```

### 5. 재배포
```bash
vercel --prod
```

### 6. 웹사이트 테스트

브라우저에서 접속:
```
https://qp-dualtetrax-dev-web.vercel.app
```

**테스트 시나리오**:
1. Landing 페이지 확인
2. 회원가입 → 이메일 확인
3. 로그인
4. Dashboard 접근
5. 디바이스 등록

---

## 🔄 업데이트 배포

코드 변경 후 재배포:

```bash
# Backend
cd backend
vercel --prod

# Frontend
cd frontend
vercel --prod
```

---

## 🐛 문제 해결

### 1. "Recursive invocation" 에러
- ✅ **해결됨**: `vercel.json`에서 `devCommand` 제거함

### 2. 환경 변수 로드 안 됨
```bash
# Vercel 대시보드에서 확인
vercel env ls

# 환경 변수 pull
vercel env pull .env.vercel
```

### 3. API CORS 에러
- Backend `vercel.json`의 `headers` 설정 확인
- Frontend `.env.production`의 `NEXT_PUBLIC_API_URL` 확인

### 4. 빌드 실패
```bash
# 로컬에서 먼저 테스트
npm run build

# Vercel 빌드 로그 확인
vercel logs
```

---

## 📊 배포 상태 확인

```bash
# 프로젝트 목록
vercel list

# 배포 상태
vercel inspect [deployment-url]

# 로그 확인
vercel logs [deployment-url]
```

---

## 🔐 보안 체크리스트

- [ ] 환경 변수가 Vercel 대시보드에만 있고 Git에는 없음
- [ ] `.env.local`, `.env.production`이 `.gitignore`에 포함됨
- [ ] `SUPABASE_SERVICE_ROLE_KEY`는 Backend만 사용
- [ ] Frontend는 `SUPABASE_ANON_KEY`만 사용
- [ ] CORS 헤더가 적절히 설정됨

---

## 📝 다음 단계

배포 완료 후:
1. ✅ Supabase RLS 정책 테스트
2. ✅ 회원가입/로그인 플로우 테스트
3. ✅ 디바이스 등록 테스트
4. ✅ API 응답 시간 모니터링
5. ⏭️ Production 환경 준비

---

## 🆘 지원

문제 발생 시:
- Vercel 대시보드: https://vercel.com/dashboard
- Vercel 로그: `vercel logs`
- Supabase 대시보드: https://supabase.com/dashboard
