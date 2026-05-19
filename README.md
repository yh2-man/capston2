# OurT - 꽃과 함께 산책하는 AI 챗봇 앱

계절 기반 꽃/산책 AI 챗봇 모바일 애플리케이션.

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
| Database | Supabase (PostgreSQL + PostGIS) |
| Auth | OAuth 2.0 (카카오 단일) |
| Storage | Oracle Cloud Object Storage |
| AI | Spring AI (OpenAI) |
| Map | Kakao Map JS SDK + WebView |
| Push | Firebase Cloud Messaging |

## 인증 아키텍처

**카카오 소셜 로그인 단일 방식** (이메일/비밀번호 없음)

```
카카오 로그인 버튼 클릭
    → 시스템 브라우저로 카카오 인증 페이지
    → auth code 발급 (콜백 딥링크)
    → 백엔드 API에 전달
    → 기존 유저: JWT 발급 → 메인 화면
    → 신규 유저: 임시 토큰 → 프로필 설정(닉네임/사진) → 가입 완료
```

## 로컬 실행 방법

### 1. 백엔드

```bash
cd flower-backend

# application-auth.yml 생성 (아래 '환경 설정' 참고)

./gradlew bootRun
# http://localhost:8080 에서 실행
```

### 2. Flutter 앱

```bash
cd flower_app

flutter pub get
flutter run
# 디바이스/에뮬레이터에서 실행
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
  kakao:
    client-id: (Kakao Developers REST API 키)
    client-secret: (Kakao Developers > 보안 탭에서 생성)
```

### Flutter 클라이언트 환경변수

`flower_app/.env` 파일 (gitignore 처리됨):

```
KAKAO_REST_API_KEY=실제-카카오-REST-API-키
```

### OAuth Redirect URI 등록

[카카오 디벨로퍼스](https://developers.kakao.com) > 내 애플리케이션 > 카카오 로그인 > Redirect URI에 등록:

```
https://ourt.kro.kr/oauth/callback        (운영)
http://localhost:5000/oauth/callback       (로컬 웹 개발)
ourt://oauth/callback                      (모바일 딥링크)
```

## 서버 배포

GitHub Actions로 자동 배포됨 (`.github/workflows/deploy.yml`):
- `main` 또는 `feature/app-ui` 브랜치에 `flower-backend/**` 또는 `flower_app/assets/map/**` 변경 push
- Oracle Cloud 인스턴스에서 systemd 서비스(`ourt-backend`)로 운영

## 현재 진행 상황

- [x] 카카오 단일 OAuth API 구현
- [x] Flutter 카카오 로그인 UI
- [x] 프로필 설정 화면 (닉네임/사진)
- [x] CORS 설정
- [x] FCM 푸시 알림 토큰 연동
- [x] 지도(꽃 명소·축제·관광지) + WebView 기반 카카오맵
- [x] 챗봇 (Spring AI / OpenAI) 통합
- [x] 꽃 도감 (농사로 API + Plant.id 자동 수집)
- [x] PostGIS 공간 인덱스 마이그레이션
- [x] Oracle Cloud Object Storage 이미지 업로드
- [x] 자동 배포 파이프라인 (GitHub Actions → Oracle Cloud)
