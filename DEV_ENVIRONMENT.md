# FLOWER 개발 환경 명세서 (Development Environment Spec)

> **문서 버전:** v1.1  
> **작성일:** 2026-04-07  
> **최종 수정:** 2026-04-07 — 전체 버전 검증 및 최신화  
> **프로젝트명:** FLOWER (꽃 정보 모바일 앱)

이 문서는 프로젝트 개발 시 사용되는 프론트엔드, 백엔드, 데이터베이스 설정 및 구체적인 패키지/버전 명세를 정의합니다. 각 파트 담당자는 반드시 본 기술 스택과 버전을 준수하여 코드를 구성해야 합니다.

---

## 1. 백엔드 (API 서버) 환경 스펙

API 서버는 RESTful 형식으로 통신하며, Spring Boot 프레임워크를 기반으로 구축됩니다. 현재 `flower-backend` 폴더 내에 초기 뼈대가 구성되어 있습니다.

| 구분 | 기술 / 스택 명 | 버전 (Version) | 비고 |
| :--- | :--- | :--- | :--- |
| **운영 프레임워크** | Spring Boot | `v4.0.5` | 2026-04 기준 최신 안정 릴리스 |
| **언어 (Language)** | Java | `17` | Spring Boot 4.0 최소 요구 버전 (LTS). 팀 환경에 따라 `21`(LTS) 권장 |
| **빌드 도구** | Gradle | `8.x` | Groovy DSL 기반 의존성 관리 |

### 1-1. 백엔드 핵심 설치 라이브러리 (Dependencies)
- **Spring WebMVC (`spring-boot-starter-web`)**: HTTP 기반 REST API 통신 모듈 구축 시 사용.
- **Spring Data JPA (`spring-boot-starter-data-jpa`)**: SQL 쿼리를 최소화하고 데이터베이스를 객체로 조회/처리하기 위한 ORM 프레임워크.
- **Spring Security (`spring-boot-starter-security`)**: 소셜 로그인(구글·카카오·네이버)의 인증 처리 권한 획득, 그리고 JWT (Access/Refresh Token) 처리를 위해 구성됨.
- **Validation (`spring-boot-starter-validation`)**: 들어오는 클라이언트 요청 값(이메일, 비밀번호 등)의 유효성 검사.
- **PostgreSQL JDBC Driver (`postgresql`)**: PostgreSQL 데이터베이스와 애플리케이션 연결 드라이버.
- **Lombok (`lombok`)**: 코드량(Getter, Setter, 생성자 등)을 극적으로 줄여주는 유틸리티 플러그인.

---

## 2. 프론트엔드 (모바일 앱) 환경 스펙

클라이언트 애플리케이션은 iOS와 Android에 동시 대응 가능한 크로스 플랫폼 프레임워크로 구현됩니다.

| 구분 | 기술 / 스택 명 | 버전 (Version) | 비고 |
| :--- | :--- | :--- | :--- |
| **프레임워크** | Flutter | `v3.41.6` | 2026-04 기준 최신 안정 릴리스. iOS 16+, Android 13+ 지원 |
| **언어 (Language)** | Dart | `v3.11` | Flutter 3.41.6에 번들 포함 (별도 설치 불필요) |

### 2-1. 프론트엔드 핵심 패키지 (Pub.dev)
- **상태 관리**: `riverpod` (앱 내 데이터 상태 구조 추적 및 관리)
- **지도 연동**: `google_maps_flutter` (인앱 지도 및 꽃 위치 마커 렌더링)
- **네트워킹**: `dio`
- **소셜 로그인**: 
  - `google_sign_in` (구글 Oauth 연동)
  - `kakao_flutter_sdk_user` (카카오 연동)
  - `flutter_naver_login` (네이버 연동)

---

## 3. 데이터베이스 (Database) 스펙

꽃의 위도·경도 등 지리적 데이터를 관리 및 쿼리하는 특수 목적형 환경이 필요합니다.

| 구분 | 기술 / 스택 명 | 버전 (Version) | 비고 |
| :--- | :--- | :--- | :--- |
| **메인 RDBMS** | PostgreSQL | `v18.3` | 2026-02 릴리스. 최신 안정 버전 |
| **공간 확장 플러그인** | PostGIS | `v3.6.2` | 2026-02 릴리스. PostgreSQL 18과 호환. 거리계산(ST_Distance) 및 반경 탐색 필수 |

---

## 4. 기타 및 인프라 (AI / 클라우드 연동) 스펙

- **푸시 모델 서버 알람**: `Firebase Cloud Messaging (FCM) API v1` (사용자 주변 꽃 감지 푸시 전송)
- **이미지 및 문서 클라우드 저장소**: `GitHub 제공 저장소` (커뮤니티 사진 등 미디어 등록 시 사용)
- **서버 인프라 구동 환경**: `Oracle Cloud (OCI)` (Spring Boot 백엔드 서버 및 DB 구동 배포처)
- **지능형 챗봇 응답 모델**: `OpenAI API (GPT-4 / GPT-4o 등 최신버전)` + RAG 구조 혼합 사용
