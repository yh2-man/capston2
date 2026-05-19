# 🔐 AUTH 모듈 — 인증/회원 시스템

> **담당:** 백엔드 서버
> **기술 스택:** JWT (Access/Refresh Token) + OAuth 2.0 (Kakao)
> **역할:** 카카오 소셜 로그인, 토큰 발급 및 검증, 회원 정보 관리

---

## 📂 패키지 구조

```
auth/
├── User.java                    # 회원 엔티티 (DB 테이블 매핑)
├── UserRepository.java          # DB 조회/저장 인터페이스
├── AuthDto.java                 # 요청/응답 데이터 형식 모음
├── AuthException.java           # 인증 관련 커스텀 예외
├── AuthService.java             # 핵심 비즈니스 로직 (카카오 소셜 로그인 흐름)
├── AuthController.java          # API 엔드포인트
├── JwtProvider.java             # JWT 토큰 발급 및 검증
├── JwtAuthenticationFilter.java # 모든 요청에서 JWT 자동 검사하는 필터
├── SecurityConfig.java          # Spring Security 보안 설정
├── OAuthProperties.java         # 카카오 API 키를 YAML에서 읽어오는 설정
├── OAuthService.java            # 카카오 서버와 실제 HTTP 통신
└── OAuthCallbackController.java # OAuth 콜백 처리
```

---

## ⚠️ 깃에 올라가지 않는 파일 (로컬에 직접 만들어야 함!)

> 이 파일은 **카카오 OAuth API 키**를 담고 있어서 `.gitignore`로 보호되어 있습니다.
> 클론 직후에는 **존재하지 않으므로** 아래 방법대로 직접 만들어야 서버가 정상 실행됩니다.

| 파일 경로 | 역할 |
|-----------|------|
| `src/main/resources/application-auth.yml` | 카카오 OAuth 클라이언트 키 + JWT secret 설정 |

---

## 🔑 카카오 OAuth 키 발급받기

1. [카카오 디벨로퍼스](https://developers.kakao.com/) 접속 후 로그인
2. **내 애플리케이션 → 애플리케이션 추가하기** (또는 기존 앱 선택)
3. **앱 키** 화면에서 **REST API 키** 복사 → `client-id`
4. **제품 설정 → 카카오 로그인** 활성화 (ON)
5. **보안** 탭에서 **Client Secret** 생성 → `client-secret`
6. **Redirect URI** 등록:
   ```
   https://ourt.kro.kr/oauth/callback
   http://localhost:5000/oauth/callback  (로컬 개발용)
   ```
7. **동의항목**에서 닉네임, 프로필 사진 등을 "필수 동의"로 설정

---

## 📄 `application-auth.yml` 파일 생성

아래 경로에 파일을 새로 만듭니다:

```
flower-backend/
└── src/
    └── main/
        └── resources/
            └── application-auth.yml   ← 여기에 생성!
```

파일 내용 (발급받은 키 값을 직접 채워 넣으세요):

```yaml
spring:
  security:
    jwt:
      secret-key: "여기에_32자_이상의_랜덤_문자열_입력"  # JWT 서명에 사용하는 비밀키
      access-token-expiry: 3600        # Access Token 유효시간 (초) — 1시간
      refresh-token-expiry: 2592000    # Refresh Token 유효시간 (초) — 30일

oauth:
  kakao:
    client-id: "여기에-카카오-REST-API-키"
    client-secret: "여기에-카카오-Client-Secret"
```

> **JWT Secret Key 생성 팁:** 아무 랜덤 문자열이나 32자 이상 입력하면 됩니다.
> 예: `flower-jwt-secret-key-2026-very-long-string-here`

---

## 🌐 API 엔드포인트 목록

Base URL: `http://localhost:8080/api/v1/auth`

| 메서드 | 경로 | 설명 | 인증 필요 |
|--------|------|------|-----------|
| `POST` | `/oauth/kakao` | 카카오 소셜 로그인 | ❌ |
| `POST` | `/refresh` | Access Token 재발급 | ❌ |
| `POST` | `/logout` | 로그아웃 (FCM 토큰 초기화) | ✅ |
| `POST` | `/profile-setup` | 소셜 신규 회원 닉네임/프로필 설정 | ❌ (tempToken) |
| `POST` | `/fcm-token` | FCM 기기 토큰 등록/갱신 | ✅ |

---

## 🔄 카카오 소셜 로그인 흐름

```
1. 앱(Flutter) → 시스템 브라우저로 카카오 인증 페이지 열기
2. 사용자 카카오 로그인 → 콜백 딥링크(ourt://)로 auth_code 수신
3. 앱 → 서버: POST /api/v1/auth/oauth/kakao { authCode, redirectUri }
4. 서버 → 카카오 서버: auth_code를 Access Token으로 교환
5. 서버 → 카카오 서버: Access Token으로 유저 프로필(닉네임, 프로필사진) 조회
6. 서버: 기존 회원? → 바로 JWT(Access+Refresh) 발급
        신규 회원? → tempToken + isNewUser:true 반환
7. 신규 회원: 앱에서 닉네임 입력 화면 → /profile-setup 호출 → 최종 가입 및 JWT 발급
```

---

## 🔒 인증이 필요한 API 호출 방법

로그인 성공 후 받은 **Access Token**을 모든 요청 헤더에 포함합니다:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## ✅ 설정 확인

파일을 올바르게 만들었다면 서버 시작 시 별다른 오류 없이 구동됩니다.

카카오 로그인 정상 동작 확인:

```
POST http://localhost:8080/api/v1/auth/oauth/kakao
Content-Type: application/json

{
  "authCode": "카카오에서 받은 auth_code",
  "redirectUri": "https://ourt.kro.kr/oauth/callback"
}
```

---

## 🚫 자주 하는 실수

| 증상 | 원인 | 해결 |
|------|------|------|
| 서버 시작 시 `jwt.secret-key` 오류 | `application-auth.yml` 없음 | 위 파일 생성 안내 참고 |
| 카카오 로그인 시 `INVALID_OAUTH_CODE` | API 키가 잘못되었거나 redirect URI 불일치 | yml 파일에 실제 키 값 입력 + 카카오 콘솔의 Redirect URI 확인 |
| `401 Unauthorized` | Authorization 헤더 누락 또는 토큰 만료 | Access Token 재발급 후 재시도 |
| `KAKAO_TOKEN_REQUEST_FAILED` | Client Secret 비활성화 또는 잘못 입력 | 카카오 콘솔 > 보안 > Client Secret이 활성화 상태인지 확인 |
