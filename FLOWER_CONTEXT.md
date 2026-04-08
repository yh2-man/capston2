# FLOWER 프로젝트 핵심 컨텍스트

> **이 파일은 모든 AI 코드 요청 시 항상 포함하는 압축 문서입니다.**  
> 상세 내용은 `FLOWER_PRD.md`, `FLOWER_API_Spec.md` 참고.

## 프로젝트 한줄 요약

꽃 위치 정보 + 지능형 챗봇 + 커뮤니티를 결합한 모바일 앱. 고령층 접근성 핵심.

## 기술 스택 (확정 버전)

> 상세 설명은 `DEV_ENVIRONMENT.md` 참고.

| 계층 | 기술 | 버전 |
|------|------|------|
| 앱 | Flutter / Dart | `v3.41` / `v3.11` |
| 서버 | Spring Boot (Java) | `v4.0.5` / Java `17` |
| 빌드 | Gradle | `8.x` |
| DB | PostgreSQL + PostGIS | `v18.3` + `v3.6.2` |
| 인증 | JWT (Access + Refresh) / OAuth (Google, Kakao, Naver) | - |
| 챗봇 | OpenAI API + RAG | GPT-4o |
| 알림 | FCM | API v1 |
| 저장소 | GitHub 제공 저장소 | 미디어 호스팅 |
| 배포 | Oracle Cloud (OCI) | - |
| ML | Python (scikit-learn, XGBoost) | `3.14.3` |

## API 공통 규칙

- 베이스 URL: `https://api.FLOWER.app/api/v1`
- 인증 헤더: `Authorization: Bearer {access_token}`
- 성공 응답: `{ "success": true, "data": {...}, "meta": {...} }`
- 실패 응답: `{ "success": false, "error": { "code": "...", "message": "..." } }`
- 페이지네이션: 커서 기반 (`cursor`, `limit`, `next_cursor`, `has_next`)

## 기능 목록 (5개)

| ID | 기능 | 우선순위 | Task Card 위치 |
|----|------|----------|----------------|
| AUTH | 인증 (이메일 + 소셜 로그인) | P0 | `tasks/AUTH/CONTEXT.md` |
| MAP | 지도 기반 꽃 위치 표시 + 알림 | P0 | `tasks/MAP/CONTEXT.md` |
| NOTIFICATION | 푸시 알림 | P0 | `tasks/NOTIFICATION/CONTEXT.md` |
| CHATBOT | 지능형 챗봇 (텍스트/음성) | P0 | `tasks/CHATBOT/CONTEXT.md` |
| COMMUNITY | 커뮤니티 (게시글/댓글/좋아요) | P1 | `tasks/COMMUNITY/CONTEXT.md` |

## 프로젝트 폴더 구조

```
FLOWER/
├── FLOWER_CONTEXT.md               ← AI 요청 시 항상 포함 (이 파일)
├── FLOWER_PRD.md                   ← 전체 기획서 (원본)
├── FLOWER_API_Spec.md              ← 전체 API 명세 (원본)
├── DEV_ENVIRONMENT.md              ← 개발 환경 버전 명세
├── tasks/                          ← 기능별 작업 공간
│   ├── AUTH/
│   │   ├── CONTEXT.md              ← AI 지시서 (항상 포함)
│   │   └── *.java / *.dart         ← AI 생성 코드 초안 (검토 후 이동)
│   ├── MAP/
│   ├── NOTIFICATION/
│   ├── CHATBOT/
│   └── COMMUNITY/
└── flower-backend/                 ← Spring Boot 백엔드 (실제 실행 코드)
    └── src/main/java/com/flower/backend/
        ├── auth/                   ← tasks/AUTH/ 검토 완료 코드 이동처
        ├── flower/
        ├── notification/
        ├── chatbot/
        └── community/
```

## 코드 작업 워크플로우

```
1단계: AI에게 코드 요청
       → FLOWER_CONTEXT.md + tasks/{기능}/CONTEXT.md 제공
                    ↓
2단계: AI가 생성한 코드를 tasks/{기능}/ 폴더에 저장
       → 파일명: AuthController.java, AuthService.java 등
                    ↓
3단계: 코드 검토 (읽어보기, AI에게 설명 요청)
                    ↓
4단계: 검토 완료 → flower-backend/src/.../auth/ 에 복사
                    ↓
5단계: ./gradlew bootRun 으로 서버 실행 + 테스트
```

> ⚠️ 테스트(실행)는 반드시 `flower-backend/`에 코드가 있어야 가능합니다.  
> `tasks/`의 코드는 초안 보관용이며 직접 실행되지 않습니다.

## 코드 작성 규칙

### 공통
- 파일 최상단 주석: `// [기능 ID: MAP-01] [명세 근거: PRD v1.2 §4.1]`
- 환경변수: `.env` 또는 `application.yml`에서 관리, 코드 내 하드코딩 금지
- API 엔드포인트: RESTful (`/api/v1/{resource}`)

### 백엔드 (Spring Boot)
- 베이스 패키지: `com.flower.backend`
- 기능별 패키지 구조: `com.flower.backend.{feature}/`
  - 예: `com.flower.backend.auth/`, `com.flower.backend.flower/`
- 레이어 구조: `controller` → `service` → `repository`

### 프론트엔드 (Flutter)
- 기능별 폴더: `lib/features/{feature_name}/`
  - 예: `lib/features/auth/`, `lib/features/map/`
- 상태 관리: `riverpod`

## DB 핵심 테이블 (4개)

```
flowers   (id, name, species, location, address, bloom_start, bloom_end, status)
users     (id, email, nickname, provider, provider_id, created_at)
posts     (id, user_id, flower_id, content, image_url, location, likes_count)
comments  (id, post_id, user_id, content, created_at)
```
