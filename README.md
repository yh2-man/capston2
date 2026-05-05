# OurT - 꽃과 함께 산책하는 AI 챗봇 앱

계절 기반 꽃/등산 AI 챗봇 모바일 애플리케이션.

## 프로젝트 구조

```
├── flower-backend/     # Spring Boot 3.4.1 (Java 17) 백엔드
├── flower_app/         # Flutter 클라이언트 앱
└── tasks/              # 작업 참고 자료
```

## 기술 스택

| 구분 | 기술 |
|------|------|
| Backend | Spring Boot 3.4.1, Java 17, JPA, Spring Security |
| Frontend | Flutter (Dart) |
| Database | Supabase (PostgreSQL) / 로컬 테스트: H2 |
| Auth | OAuth 2.0 (카카오, 구글, 네이버) |
| Storage | Oracle Cloud Object Storage (예정) |

## 인증 아키텍처

100% **소셜 로그인 전용** (이메일/비밀번호 없음)

```
소셜 로그인 버튼 클릭
    → OAuth 인증 페이지 (카카오/구글/네이버)
    → auth code 발급
    → 백엔드 API에 전달
    → 기존 유저: JWT 발급 → 메인 화면
    → 신규 유저: 임시 토큰 → 프로필 설정(닉네임/사진) → 가입 완료
```

## 로컬 실행 방법

### 1. 백엔드

```bash
cd flower-backend

# application-auth.yml 생성 (아래 '환경 설정' 참고)
# 로컬 테스트는 H2 인메모리 DB 사용 (설정 완료 상태)

./gradlew bootRun
# http://localhost:8080 에서 실행
# H2 콘솔: http://localhost:8080/h2-console
```

### 2. Flutter 앱

```bash
cd flower_app

flutter pub get
flutter run -d chrome --web-port=5000
# http://localhost:5000 에서 실행
```

## 환경 설정 (시크릿 파일)

### `flower-backend/src/main/resources/application-auth.yml`

이 파일은 `.gitignore`에 포함되어 Git에 올라가지 않습니다.
아래 내용을 복사하여 직접 생성해 주세요:

```yaml
jwt:
  secret: 최소-32바이트-이상의-시크릿-키-입력
  access-token-validity-seconds: 3600
  refresh-token-validity-seconds: 604800

oauth:
  google:
    client-id: (Google Cloud Console에서 발급)
    client-secret: (Google Cloud Console에서 발급)
  kakao:
    client-id: (Kakao Developers REST API 키)
    client-secret: (Kakao Developers 보안 탭에서 생성)
  naver:
    client-id: (Naver Developers에서 발급)
    client-secret: (Naver Developers에서 발급)
```

### Flutter 클라이언트 OAuth 키 설정

`flower_app/lib/screens/login_screen.dart` 파일에서 각 소셜 버튼의 `clientId`를 실제 키로 교체:

```dart
const clientId = 'YOUR_KAKAO_REST_API_KEY';   // 카카오 REST API 키
const clientId = 'YOUR_GOOGLE_CLIENT_ID';      // 구글 Client ID
const clientId = 'YOUR_NAVER_CLIENT_ID';       // 네이버 Client ID
```

### OAuth Redirect URI 등록

각 소셜 서비스 개발자 콘솔에서 아래 Redirect URI를 등록:

```
http://localhost:5000/oauth-callback
```

## 서버 배포 시 변경 사항

`application.yml`에서 DB를 PostgreSQL(Supabase)로 변경:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://<SUPABASE_HOST>:5432/postgres
    username: <USERNAME>
    password: <PASSWORD>
    driver-class-name: org.postgresql.Driver
```

## 현재 진행 상황

- [x] 소셜 로그인 전용 백엔드 리팩토링 완료
- [x] 카카오/구글/네이버 OAuth API 구현
- [x] Flutter 로그인 UI (소셜 버튼 3개)
- [x] 프로필 설정 화면 (닉네임/사진)
- [x] CORS 설정
- [ ] OAuth 카카오 Client Secret 인증 오류 해결 중
- [ ] 프로필 이미지 업로드 (Oracle Cloud Storage)
- [ ] 메인 화면 기능 구현
