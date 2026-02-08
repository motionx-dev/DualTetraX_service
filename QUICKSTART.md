# DualTetraX Services - Quick Start (15분)

**목표**: Backend + Frontend를 로컬에서 실행하고 첫 디바이스 등록까지 완료

---

## 📋 체크리스트

### 1️⃣ Supabase 설정 (5분)
- [ ] https://supabase.com 접속 및 로그인
- [ ] 새 프로젝트 생성: `qp-dualtetrax-dev`
- [ ] Settings → API에서 복사:
  - [ ] Project URL
  - [ ] anon public key
  - [ ] service_role key
- [ ] SQL Editor에서 `doc/database_schema.md` 스크립트 실행
- [ ] Table Editor에서 테이블 생성 확인 (users, devices 등)

### 2️⃣ Upstash Redis 설정 (3분)
- [ ] https://console.upstash.com 접속 및 로그인
- [ ] 새 Redis DB 생성: `dualtetrax-jwt-blacklist`
- [ ] REST API 탭에서 복사:
  - [ ] UPSTASH_REDIS_REST_URL
  - [ ] UPSTASH_REDIS_REST_TOKEN

### 3️⃣ Backend 설정 (2분)
```bash
cd backend
cp .env.example .env.local
# .env.local 파일을 열어서 Supabase와 Upstash 정보 입력
npm install
npm run dev
```
- [ ] http://localhost:3000/api/health 접속 확인

### 4️⃣ Frontend 설정 (2분)
```bash
cd frontend
cp .env.example .env.local
# .env.local 파일을 열어서 Supabase 정보 입력
npm install
npm run dev
```
- [ ] http://localhost:3001 접속 확인

### 5️⃣ 통합 테스트 (3분)
- [ ] 회원가입: test@example.com / Test1234!@#
- [ ] Supabase → Auth → Users에서 이메일 확인 처리
- [ ] 로그인
- [ ] 디바이스 등록: DTX-20260208-001
- [ ] 대시보드에서 디바이스 확인
- [ ] 로그아웃

---

## 🚀 빠른 명령어

### 환경 확인
```bash
cd /Users/oz/motionx/qp_prjs/DualTetraX/services
./setup-check.sh
```

### Backend 실행
```bash
cd backend
npm run dev
# http://localhost:3000
```

### Frontend 실행 (새 터미널)
```bash
cd frontend
npm run dev
# http://localhost:3001
```

---

## 📖 상세 가이드

전체 설정 방법은 다음 파일 참조:
```
services/SETUP_GUIDE.md
```

---

## ❓ 자주 묻는 질문

**Q1: 이메일 확인이 오지 않아요**
A: Supabase 무료 플랜은 실제 이메일을 보내지 않습니다.
   → Supabase 대시보드 → Authentication → Users에서 수동으로 "Confirm email" 클릭

**Q2: "이미 등록된 시리얼 번호입니다" 오류**
A: Supabase Table Editor → devices 테이블에서 해당 행 삭제 후 재시도

**Q3: Backend 포트 3000이 이미 사용 중이에요**
A: `lsof -ti:3000 | xargs kill -9` 실행 후 재시도

**Q4: Supabase URL은 어디서 찾나요?**
A: Supabase 대시보드 → Settings → API → Project URL

---

## 🎯 다음 단계

로컬 테스트 완료 후:
1. **Vercel 배포** (Dev 환경)
2. **모바일 앱 통합** (Backend API 연결)
3. **관리자 콘솔** 구현
4. **CI/CD** 설정

---

## 🆘 문제 발생 시

1. `./setup-check.sh` 실행하여 환경 확인
2. `SETUP_GUIDE.md`의 "문제 해결" 섹션 참조
3. Backend 터미널 로그 확인
4. Browser Console (F12) 로그 확인
