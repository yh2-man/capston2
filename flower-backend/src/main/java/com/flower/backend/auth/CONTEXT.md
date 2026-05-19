# Task Card: AUTH — 인증 (카카오 소셜 로그인)

> **연관 PRD:** §4.0 AUTH-01 ~ AUTH-03
> **우선순위:** P0 (MVP 필수)
> **함께 읽기:** `FLOWER_CONTEXT.md` (항상 포함)

---

## 기능 요약

| ID | 요구사항 |
|----|----------|
| AUTH-01 | 카카오 소셜 로그인 (유일한 로그인 수단) |
| AUTH-02 | 소셜 최초 가입 시 닉네임/프로필 사진 입력 |
| AUTH-03 | JWT Access + Refresh Token 인증 유지 |

> ⚠️ 이메일/비밀번호 회원가입, 구글/네이버 로그인은 **MVP 범위에서 제외**됨.
> 단일 로그인 수단으로 회원 모델·UI·OAuth 분기 로직을 단순화했음.

---

## 외부 연동 API

| 서비스 | API 이름 | 용도 | 비용 |
| :--- | :--- | :--- | :--- |
| **카카오** | Kakao Login API (REST API) | 카카오 계정 간편 로그인 | 무료 |

---

## API 엔드포인트

### 1. 카카오 소셜 로그인
```
POST /api/v1/auth/oauth/kakao  (인증 불필요)
Body: { authCode, redirectUri }

→ 200 (기존 회원): { isNewUser: false, accessToken, refreshToken, expiresIn, user }
→ 200 (신규 회원): { isNewUser: true, tempToken, provider, providerEmail? }

에러: INVALID_OAUTH_CODE(401), OAUTH_UPSTREAM_ERROR(500)
```

### 2. 토큰 갱신
```
POST /api/v1/auth/refresh  (인증 불필요)
Body: { refresh_token }
→ 200: { access_token, expires_in }
에러: INVALID_REFRESH_TOKEN(401)
```

### 3. 로그아웃
```
POST /api/v1/auth/logout  (🔒 인증 필요)
Body: { refresh_token }
→ 200: { data: null }
부수효과: FCM 토큰 초기화
```

### 4. 프로필 설정 (신규 소셜 회원)
```
POST /api/v1/auth/profile-setup  (tempToken으로 인증)
Body: { tempToken, nickname (2~10자), profileImageUrl? }
→ 201: { accessToken, refreshToken, expiresIn, user }
에러: TEMP_TOKEN_EXPIRED(401), NICKNAME_ALREADY_EXISTS(409), INVALID_NICKNAME_LENGTH(400)
```

### 5. FCM 토큰 등록/갱신
```
POST /api/v1/auth/fcm-token  (🔒 인증 필요)
Body: { fcmToken }
→ 200: { data: null }
```

---

## 카카오 소셜 로그인 흐름

```
[앱] 시스템 브라우저로 카카오 인증 페이지 호출 → 사용자 로그인
[카카오] 콜백 딥링크(ourt://)로 auth_code 전달
[앱 → 서버] /api/v1/auth/oauth/kakao { authCode, redirectUri }
[서버 → 카카오] auth_code를 Access Token으로 교환 → 사용자 프로필 조회
  → 신규: 계정 생성 + temp_token 발급 → 닉네임 설정 → JWT 발급
  → 기존: JWT 바로 발급
```

---

## 작업 체크리스트

- [x] Flutter: 카카오 로그인 화면 UI (`login_screen.dart`)
- [x] Flutter: `flutter_web_auth_2`로 시스템 브라우저 OAuth 흐름 구현
- [x] Flutter: 토큰 저장 (SharedPreferences)
- [x] Flutter: 닉네임/프로필 설정 화면 (`profile_setup_screen.dart`)
- [x] 서버: `/api/v1/auth/*` 엔드포인트 구현
- [x] 서버: JWT 발급/검증 (Access/Refresh/Temp Token)
- [x] 서버: JWT 인증 필터 (`JwtAuthenticationFilter`)
- [x] 서버: Kakao OAuth 토큰 교환 + 프로필 조회 (`OAuthService`)
- [x] 서버: `users` 테이블 (provider=KAKAO, providerId, nickname, fcmToken, role)
- [x] 서버: Spring Security 설정 (`SecurityConfig` — BCrypt, Stateless 세션)
