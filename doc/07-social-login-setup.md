# DualTetraX 소셜 로그인 설정 가이드

**버전**: 1.0
**작성일**: 2026-02-08

> DualTetraX 서비스는 **Google**, **Apple**, **Kakao** 3개 OAuth 프로바이더를 지원합니다.
> Supabase Auth가 OAuth 흐름을 처리하므로, 각 프로바이더에서 발급한 키를 Supabase에 등록하면 됩니다.

---

## 1. 전체 인증 흐름

```
사용자 → [Google/Apple/Kakao 로그인 버튼 클릭]
  → Supabase Auth → 프로바이더 OAuth 페이지로 리다이렉트
  → 사용자가 동의/로그인
  → 프로바이더 → Supabase 콜백 URL로 리다이렉트 (code 포함)
  → Supabase → 프론트엔드 /auth/callback 으로 리다이렉트
  → /auth/callback: code → session 교환, role 확인 후 리다이렉트
      ├─ admin → /admin
      └─ user  → /dashboard
```

### 관련 코드

| 파일 | 역할 |
|------|------|
| `frontend/src/components/SocialLoginButtons.tsx` | 소셜 로그인 버튼 UI + `signInWithOAuth()` 호출 |
| `frontend/src/app/auth/callback/route.ts` | OAuth 콜백 처리 (code → session, role 기반 리다이렉트) |
| `frontend/src/app/login/page.tsx` | 로그인 페이지 (이메일 + 소셜 버튼) |
| `frontend/src/app/signup/page.tsx` | 회원가입 페이지 (이메일 + 소셜 버튼) |
| `mobile_app/lib/data/datasources/auth_remote_data_source.dart` | 모바일 OAuth (Google, Apple) |

---

## 2. Supabase 설정 (공통)

### 2.1 Redirect URL 등록

Supabase Dashboard → **Authentication** → **URL Configuration**

| 필드 | 값 |
|------|-----|
| Site URL | `https://frontend-seven-gamma-56.vercel.app` |
| Redirect URLs | `https://frontend-seven-gamma-56.vercel.app/auth/callback` |

> 개발 환경 추가: `http://localhost:3000/auth/callback`

### 2.2 프로바이더 활성화

Supabase Dashboard → **Authentication** → **Providers**

각 프로바이더(Google, Apple, Kakao)를 켜고 아래 섹션에서 얻은 키를 입력합니다.

---

## 3. Google OAuth 설정

### 3.1 Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 또는 새 프로젝트 생성

### 3.2 OAuth 동의 화면 설정

**APIs & Services** → **OAuth consent screen**

| 필드 | 값 |
|------|-----|
| User Type | External |
| App name | DualTetraX |
| User support email | (관리자 이메일) |
| App logo | (선택) |
| Authorized domains | `supabase.co` |
| Developer contact email | (관리자 이메일) |

**Scopes** 추가:
- `email`
- `profile`
- `openid`

### 3.3 OAuth 2.0 클라이언트 ID 생성

**APIs & Services** → **Credentials** → **+ CREATE CREDENTIALS** → **OAuth client ID**

#### 웹 클라이언트 (프론트엔드용)

| 필드 | 값 |
|------|-----|
| Application type | Web application |
| Name | DualTetraX Web |
| Authorized JavaScript origins | `https://frontend-seven-gamma-56.vercel.app` |
| Authorized redirect URIs | `https://<SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback` |

> `<SUPABASE_PROJECT_REF>`는 Supabase 프로젝트 URL에서 확인 (예: `abcdefghijklmnop`)

#### iOS 클라이언트 (모바일용)

| 필드 | 값 |
|------|-----|
| Application type | iOS |
| Name | DualTetraX iOS |
| Bundle ID | (Flutter 앱 Bundle ID, 예: `com.dualtetrax.app`) |

#### Android 클라이언트 (모바일용)

| 필드 | 값 |
|------|-----|
| Application type | Android |
| Name | DualTetraX Android |
| Package name | (Flutter 앱 Package, 예: `com.dualtetrax.app`) |
| SHA-1 certificate fingerprint | (아래 명령으로 확인) |

```bash
# Debug SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android

# Release SHA-1
keytool -list -v -keystore <release-keystore-path> -alias <alias-name>
```

### 3.4 Supabase에 등록

Supabase Dashboard → **Authentication** → **Providers** → **Google**

| 필드 | 값 |
|------|-----|
| Enabled | ON |
| Client ID | (웹 클라이언트 ID) |
| Client Secret | (웹 클라이언트 Secret) |

---

## 4. Apple Sign-In 설정

### 4.1 사전 요구사항

- Apple Developer Program 멤버십 (연 $99)
- [Apple Developer](https://developer.apple.com/) 계정

### 4.2 App ID 설정

**Certificates, Identifiers & Profiles** → **Identifiers** → **App IDs**

1. 기존 App ID 선택 또는 새로 생성
2. **Sign In with Apple** 체크 → **Edit**
3. **Enable as a primary App ID** 선택

### 4.3 Services ID 생성 (웹용)

**Identifiers** → **+** → **Services IDs**

| 필드 | 값 |
|------|-----|
| Description | DualTetraX Web Login |
| Identifier | `com.dualtetrax.web` (예시) |

등록 후:
1. **Sign In with Apple** 체크 → **Configure**
2. Primary App ID: 위에서 설정한 App ID 선택
3. Domains and Subdomains: `<SUPABASE_PROJECT_REF>.supabase.co`
4. Return URLs: `https://<SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback`

### 4.4 Key 생성

**Keys** → **+**

| 필드 | 값 |
|------|-----|
| Key Name | DualTetraX Auth Key |
| Sign In with Apple | 체크 → Configure → Primary App ID 선택 |

**Register** 클릭 → `.p8` 파일 다운로드 (한 번만 가능, 안전 보관)

기록할 값:
- **Key ID**: 키 목록에서 확인
- **Team ID**: 우측 상단 계정 이름 옆 또는 Membership 페이지

### 4.5 Supabase에 등록

Supabase Dashboard → **Authentication** → **Providers** → **Apple**

| 필드 | 값 |
|------|-----|
| Enabled | ON |
| Client ID | Services ID의 Identifier (예: `com.dualtetrax.web`) |
| Secret Key | `.p8` 파일 내용 전체 (-----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY-----) |
| Key ID | Apple Developer에서 확인한 Key ID |
| Team ID | Apple Developer에서 확인한 Team ID |

### 4.6 모바일 앱 추가 설정 (iOS)

Xcode → Runner → **Signing & Capabilities** → **+ Capability** → **Sign In with Apple** 추가

`ios/Runner.entitlements`:
```xml
<dict>
  <key>com.apple.developer.applesignin</key>
  <array>
    <string>Default</string>
  </array>
</dict>
```

---

## 5. Kakao 로그인 설정

> **참고**: 카카오 개발자 포털이 2025년 하반기에 UI를 개편했습니다.
> 아래는 최신 포털 구조에 맞춘 설정 가이드입니다.
>
> - [Supabase 공식 Kakao 가이드](https://supabase.com/docs/guides/auth/social-login/auth-kakao)
> - [카카오 로그인 설정하기](https://developers.kakao.com/docs/latest/ko/kakaologin/prerequisite)
> - [카카오 로그인 REST API](https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api)

### 5.1 Kakao Developers 앱 생성

1. [Kakao Developers](https://developers.kakao.com/) 접속 → 우측 상단 **로그인**
2. 상단 메뉴 **App** 클릭 → **Create app** (앱 만들기)

| 필드 | 설명 |
|------|------|
| 앱 아이콘 | (선택) |
| 앱 이름 | DualTetraX |
| 사업자명 | (회사명) |
| 카테고리 | 건강/뷰티 또는 해당 업종 |
| 대표 도메인 | `https://frontend-seven-gamma-56.vercel.app` |

**저장** 클릭하여 앱 등록 완료

### 5.2 REST API 키 확인 (Client ID)

**App** → 생성한 앱 선택 → **앱 설정** → **앱** → **플랫폼 키**

여기서 **REST API 키**를 확인합니다. 이 값이 Supabase의 `Client ID`가 됩니다.

### 5.3 Supabase 콜백 URL 확인

Supabase Dashboard → **Authentication** → **Sign In / Providers** → **Kakao** 펼치기

표시되는 **Callback URL**을 복사합니다:
```
https://<SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback
```

### 5.4 Redirect URI 등록

카카오 개발자 포털로 돌아가서:

**앱 설정** → **앱** → **플랫폼 키** → REST API 키 클릭

**카카오 로그인 Redirect URI** 필드에 위에서 복사한 Supabase 콜백 URL 입력:
```
https://<SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback
```

> 로컬 개발 시 추가: `http://localhost:54321/auth/v1/callback` (Supabase CLI 사용 시)

### 5.5 카카오 로그인 활성화

**제품 설정** → **카카오 로그인** → **일반**

| 필드 | 값 |
|------|-----|
| 사용 설정 → 상태 | **ON** |

### 5.6 Client Secret 생성 및 활성화

**앱 설정** → **앱** → **플랫폼 키** → REST API 키 클릭

**카카오 로그인 Client Secret** 항목에서:

| 단계 | 설명 |
|------|------|
| 1 | **코드 생성** 버튼 클릭 → Client Secret 코드 발급 |
| 2 | **카카오 로그인 Client Secret** 토글을 **활성화** |

> REST API 키로 앱을 추가하면 Client Secret이 기본 활성 상태입니다.
> 토큰 발급 시 `client_secret` 파라미터를 반드시 포함해야 합니다.

### 5.7 동의항목 설정

**제품 설정** → **카카오 로그인** → **동의항목**

| 항목 (scope) | 설정 | 비고 |
|------|------|------|
| `profile_nickname` (닉네임) | 필수 동의 | |
| `profile_image` (프로필 사진) | 선택 동의 | |
| `account_email` (카카오계정 이메일) | **필수 동의** | 비즈 앱 전환 필요 |

> Supabase Auth는 사용자 식별에 이메일을 사용하므로 `account_email`이 **필수**입니다.
> 이메일 필수 동의는 **비즈 앱** 전환 후에만 설정할 수 있습니다.

### 5.8 비즈 앱 전환

`account_email` 필수 동의를 위해 비즈 앱 전환이 **반드시 필요**합니다.

**앱 설정** → **앱** → **일반** → 비즈니스 정보 입력

| 유형 | 필요 서류 |
|------|-----------|
| 개인 개발자 | 본인 인증 (전화번호 인증) |
| 사업자 | 사업자등록증 업로드 |

> 비즈 앱 심사 없이 즉시 전환 가능합니다 (개인 개발자의 경우).
> 일부 동의항목은 추가 기능 신청 후 심사(영업일 3~5일) 통과가 필요할 수 있습니다.

### 5.9 OpenID Connect 활성화 (선택)

**제품 설정** → **카카오 로그인** → **OpenID Connect**

| 필드 | 값 |
|------|-----|
| 상태 | **ON** |

활성화 시 액세스 토큰과 함께 **ID 토큰**을 동시 발급받습니다.
Kakao JS SDK를 직접 사용할 때 `signInWithIdToken()` 방식으로 인증할 수 있습니다:

```typescript
// Kakao JS SDK로 직접 로그인 후 ID Token으로 Supabase 인증
const res = await supabase.auth.signInWithIdToken({
  provider: 'kakao',
  token: id_token,
});
```

> DualTetraX는 `signInWithOAuth()` 방식을 사용하므로 OpenID Connect 활성화는 **선택사항**입니다.

### 5.10 Supabase에 등록

Supabase Dashboard → **Authentication** → **Providers** → **Kakao**

| 필드 | 값 |
|------|-----|
| Enabled | **ON** |
| Client ID | REST API 키 (5.2에서 확인) |
| Client Secret | Client Secret 코드 (5.6에서 생성) |

### 5.11 구현 코드 (참고)

#### 웹 (Next.js) — 이미 구현됨

```typescript
// frontend/src/components/SocialLoginButtons.tsx
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'kakao',
  options: {
    redirectTo: `${window.location.origin}/auth/callback`,
  },
});
```

#### 모바일 (Flutter) — 추가 구현 시

```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.kakao,
  redirectTo: kIsWeb ? null : 'com.dualtetrax.app://callback',
  authScreenLaunchMode: kIsWeb
    ? LaunchMode.platformDefault
    : LaunchMode.externalApplication,
);
```

> 모바일 앱에서 Kakao 로그인을 사용하려면 Deep Link 설정이 추가로 필요합니다.
> iOS: `Info.plist`에 URL scheme 추가, Android: `AndroidManifest.xml`에 intent-filter 추가

---

## 6. 환경별 설정 요약

### 프론트엔드 (.env)

```env
NEXT_PUBLIC_SUPABASE_URL=https://<PROJECT_REF>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon_key>
```

> 소셜 로그인 키는 프론트엔드에 **넣지 않습니다**. Supabase가 서버 사이드에서 처리합니다.

### 모바일 앱 (Flutter)

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const supabaseUrl = 'https://<PROJECT_REF>.supabase.co';
  static const supabaseAnonKey = '<anon_key>';
}
```

#### iOS 추가 설정 (Google Sign-In)

`ios/Runner/Info.plist`에 URL scheme 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.<IOS_CLIENT_ID></string>
    </array>
  </dict>
</array>
```

#### Android 추가 설정 (Google Sign-In)

`android/app/build.gradle`:
```groovy
defaultConfig {
    manifestPlaceholders += [
        'appAuthRedirectScheme': 'com.dualtetrax.app'
    ]
}
```

---

## 7. 테스트 체크리스트

### 웹 (프론트엔드)

- [ ] 로그인 페이지에서 Google 버튼 클릭 → Google 동의 화면 → 로그인 성공 → /dashboard
- [ ] 로그인 페이지에서 Apple 버튼 클릭 → Apple 동의 화면 → 로그인 성공 → /dashboard
- [ ] 로그인 페이지에서 Kakao 버튼 클릭 → 카카오 동의 화면 → 로그인 성공 → /dashboard
- [ ] 회원가입 페이지에서도 동일하게 소셜 로그인 동작 확인
- [ ] 소셜 로그인으로 최초 가입 시 `profiles` 테이블에 레코드 자동 생성 확인
- [ ] admin role 계정으로 소셜 로그인 시 /admin 으로 리다이렉트 확인
- [ ] 로그아웃 후 다시 소셜 로그인 정상 동작 확인

### 모바일 (Flutter)

- [ ] Google 로그인 (iOS) → 성공 → 메인 화면
- [ ] Google 로그인 (Android) → 성공 → 메인 화면
- [ ] Apple 로그인 (iOS만) → 성공 → 메인 화면
- [ ] 소셜 로그인 후 세션 유지 확인 (앱 재시작)
- [ ] 소셜 로그인 후 서버 프로필 동기화 확인

---

## 8. 트러블슈팅

### "OAuth redirect URI mismatch"

**원인**: 프로바이더에 등록한 Redirect URI와 Supabase의 콜백 URL이 불일치

**해결**:
1. Supabase 프로젝트 URL 확인: `https://<PROJECT_REF>.supabase.co`
2. 프로바이더에 등록할 Redirect URI: `https://<PROJECT_REF>.supabase.co/auth/v1/callback`
3. 끝에 `/` 없이 정확히 일치해야 함

### "Email not provided by OAuth provider"

**원인**: 프로바이더에서 이메일 scope를 설정하지 않음

**해결**:
- Google: OAuth consent screen에서 `email` scope 추가
- Apple: 사용자가 이메일 숨기기 선택 시 relay 이메일 제공 (정상)
- Kakao: 동의항목에서 이메일 필수 동의 설정 (비즈 앱 필요)

### Kakao 로그인 시 이메일이 null로 들어옴

**원인**: `account_email` 동의항목이 "필수 동의"가 아닌 "선택 동의"로 설정됨

**해결**:
1. 비즈 앱 전환 완료 확인 (5.8 참조)
2. 동의항목에서 `account_email`을 **필수 동의**로 변경
3. 이미 가입한 사용자는 카카오계정 설정에서 이메일 동의를 철회 후 재동의 필요

### Kakao Client Secret 관련 토큰 발급 실패

**원인**: REST API 키 추가 시 Client Secret이 기본 활성화되는데, secret 값을 Supabase에 등록하지 않음

**해결**:
1. 카카오 개발자 포털에서 Client Secret 코드 확인
2. Supabase Dashboard → Providers → Kakao에 Client Secret 입력
3. Client Secret 활성화 상태가 "사용함"인지 확인

### 모바일에서 OAuth 창이 안 열림

**원인**: Deep link 또는 URL scheme 설정 누락

**해결**:
- iOS: Info.plist에 URL scheme 추가
- Android: `appAuthRedirectScheme` manifest placeholder 설정
- `flutter clean && flutter pub get` 후 재빌드

### Apple Sign-In이 Android에서 안 됨

**원인**: Apple Sign-In은 **iOS/macOS/웹** 에서만 지원됨

**해결**: Android 앱에서는 Apple 로그인 버튼을 숨기거나, 웹 기반 Apple Sign-In으로 우회

---

## 9. 보안 고려사항

1. **Client Secret 관리**: Google/Apple/Kakao Secret은 Supabase Dashboard에만 저장. 코드나 `.env`에 노출하지 않음
2. **PKCE Flow**: Supabase SSR은 PKCE(Proof Key for Code Exchange) 흐름을 사용하여 authorization code 가로채기 공격 방지
3. **프로필 자동 생성**: Supabase의 `handle_new_user` trigger가 OAuth 가입 시 `profiles` 테이블에 자동으로 레코드 생성
4. **토큰 관리**: OAuth 토큰은 Supabase가 관리. 프론트엔드/모바일은 Supabase session 토큰만 사용
5. **Redirect URL 제한**: Supabase URL Configuration에서 허용된 Redirect URL만 등록하여 open redirect 공격 방지
