# Supabase 프로젝트 설정 가이드

## 1단계: Supabase 프로젝트 생성

1. [Supabase](https://supabase.com) 접속 및 로그인
2. "New Project" 클릭
3. 프로젝트 정보 입력:
   - **Name**: `qp-dualtetrax-dev`
   - **Database Password**: 강력한 비밀번호 생성 (저장 필요!) L$.Y*Dz?ku6XUA@
   - **Region**: Northeast Asia (Seoul) - 한국 사용자용
   - **Pricing Plan**: Free

4. "Create new project" 클릭 (약 2분 소요)

---

## 2단계: API 키 복사

프로젝트 생성 완료 후:

1. 좌측 메뉴에서 ⚙️ **Settings** 클릭
2. **API** 탭 선택
3. 다음 정보 복사:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public** key: `eyJhbGci...` (공개 키)
   - **service_role** key: `eyJhbGci...` (🔒 비밀 키 - 절대 노출 금지!)

---

## 3단계: 데이터베이스 스키마 적용

1. 좌측 메뉴에서 🗄️ **SQL Editor** 클릭
2. "+ New query" 클릭
3. `doc/database_schema.md` 파일 열기
4. SQL 스크립트 전체 복사하여 붙여넣기
5. "Run" 버튼 클릭 (⌘ + Enter)

**주요 생성 테이블:**
- ✅ `public.profiles` - 사용자 프로필
- ✅ `public.devices` - 디바이스 정보
- ✅ `public.usage_sessions` - 사용 세션
- ✅ `public.daily_statistics` - 일별 통계
- ✅ `pii.user_id_mapping` - 가명화 매핑 (보안)
- ✅ `analytics.*` - 분석용 테이블

---

## 4단계: Row Level Security (RLS) 확인

SQL Editor에서 다음 쿼리 실행하여 RLS 정책 확인:

```sql
-- RLS 활성화 확인
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- 정책 목록 확인
SELECT * FROM pg_policies;
```

**모든 테이블에서 `rowsecurity = true` 확인 필수!**

---

## 5단계: Storage 버킷 생성

1. 좌측 메뉴에서 🗂️ **Storage** 클릭
2. "Create a new bucket" 클릭
3. 다음 버킷 생성:

**버킷 1: profile-images**
- Name: `profile-images`
- Public: ✅ (체크)
- File size limit: 5MB
- Allowed MIME types: `image/jpeg, image/png, image/webp`

**버킷 2: firmware-binaries**
- Name: `firmware-binaries`
- Public: ❌ (비공개)
- File size limit: 10MB
- Allowed MIME types: `application/octet-stream`

---

## 6단계: 환경 변수 설정

### Backend (.env.local)

```bash
cd backend
cp .env.example .env.local
```

`.env.local` 파일 수정:
```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci... (anon public key)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci... (service_role key)

# Redis는 나중에 설정 (일단 주석 처리)
# UPSTASH_REDIS_REST_URL=
# UPSTASH_REDIS_REST_TOKEN=
```

### Frontend (.env.local)

```bash
cd frontend
cp .env.example .env.local
```

`.env.local` 파일 수정:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci... (anon public key만!)
```

⚠️ **주의**: Frontend는 `NEXT_PUBLIC_` 접두사 필수! `service_role` 키는 절대 포함하지 말 것!

---

## 7단계: 연결 테스트

### Backend 테스트

```bash
cd backend
npm install
npm run dev
```

브라우저에서 `http://localhost:3000/api/health` 접속

**예상 응답:**
```json
{
  "status": "ok",
  "timestamp": "2026-02-08T12:00:00.000Z",
  "supabase": "connected"
}
```

---

## 🎉 완료!

Supabase 프로젝트 설정이 완료되었습니다.

**다음 단계:**
1. Frontend 프로젝트 설정
2. 로그인/회원가입 페이지 구현
3. 대시보드 구현

---

## 📚 참고 자료

- [Supabase 공식 문서](https://supabase.com/docs)
- [Row Level Security 가이드](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
