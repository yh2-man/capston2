# OurT 아키텍처 리뷰

## 기술 스택

| 구분 | 기술 |
|---|---|
| 백엔드 | Java 17 + Spring Boot 3.4.1 |
| DB | PostgreSQL 16 + PostGIS 3.4 |
| 프론트엔드 | Flutter Web (Dart 3.11.5) |

---

## 백엔드 패키지 구조

Spring Boot는 레이어드 아키텍처가 프레임워크 자체에 내장되어 있으므로 Node.js처럼 직접 설계할 필요 없이 아래 구조를 따른다.

```
com.flower.backend/
├── auth/               ← 현재 유일하게 구현된 모듈
├── {기능명}/           ← 기능별 패키지로 수평 확장
│   ├── {기능}Controller.java
│   ├── {기능}Service.java
│   ├── {기능}Repository.java
│   ├── {기능}Entity.java
│   └── {기능}Dto.java
└── common/
    ├── exception/      ← 전역 예외 처리
    └── config/         ← Security, CORS 등 공통 설정
```

**핵심 원칙**
- 기능(도메인) 단위로 패키지를 묶는다 — `auth/`, `walk/`, `flower/` 등
- 각 패키지 안에서 Controller → Service → Repository 흐름을 유지
- Spring의 `@Controller`, `@Service`, `@Repository` 어노테이션이 레이어 분리를 강제함

---

## 현재 문제점

### 1. 에러 처리가 컨트롤러 안에 갇혀 있음

```java
// 현재: AuthController 안에 @ExceptionHandler 존재
// 기능이 늘어나면 각 컨트롤러마다 동일 코드 복붙 필요
@ExceptionHandler(AuthException.class)
public ResponseEntity<?> handleAuthException(AuthException e) { ... }
```

**개선 방향**: `common/exception/GlobalExceptionHandler.java`로 분리

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<?> handleAuthException(AuthException e) { ... }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(Exception e) { ... }
}
```

---

## PostGIS 사용 시 유의사항

지도·산책 기능 개발 시 공간 데이터 처리가 필요하다.

### 엔티티 매핑
```java
@Entity
public class WalkRoute {
    @Column(columnDefinition = "geometry(Point, 4326)")
    private Point location;  // org.locationtech.jts.geom.Point
}
```

### 공간 인덱스 (성능 필수)
```sql
-- 공간 데이터 컬럼에는 반드시 GiST 인덱스 생성
CREATE INDEX idx_walk_location ON walk_route USING GIST (location);
```

### 주요 PostGIS 함수
| 함수 | 용도 |
|---|---|
| `ST_DWithin(a, b, 거리)` | 특정 거리 내 검색 |
| `ST_Distance(a, b)` | 두 지점 간 거리 계산 |
| `ST_Intersects(a, b)` | 영역 교차 여부 |

---

## Flutter 구조

### 현재 상태
```
lib/
├── main.dart              ← OAuth 콜백 처리 포함 (역할 과다)
├── screens/               ← UI 8개 화면 (백엔드 연결은 로그인만)
├── services/              ← auth_api_service.dart 하나뿐
└── theme/                 ← 계절 테마 시스템
```

### 기능 추가 시 권장 구조
```
lib/
├── screens/
├── services/              ← API 통신 (기능별로 추가)
├── models/                ← 응답 DTO 매핑 클래스
├── theme/
└── main.dart
```

### 상태 관리
현재는 상태 관리 라이브러리 없음. 기능이 늘어나면 **Provider** 또는 **Riverpod** 도입 권장.

---

## 백엔드-앱 통신 규칙

현재 모든 응답은 아래 형식으로 통일되어 있다. **신규 API도 동일 형식을 유지한다.**

```json
// 성공
{ "success": true, "data": { ... } }

// 실패
{ "success": false, "error": { "code": "에러코드", "message": "설명" } }
```

---

## 우선순위 개선 목록

| 순위 | 항목 | 이유 |
|---|---|---|
| 1 | `GlobalExceptionHandler` 분리 | 기능 추가 전에 공통 에러 처리 기반 필요 |
| 2 | Flutter `models/` 디렉터리 생성 | API 응답을 Dart 클래스로 매핑하는 구조 필요 |
| 3 | 공간 인덱스 마이그레이션 준비 | 지도·산책 기능 개발 전 DB 스키마 설계 필요 |
| 4 | Flutter 상태 관리 도입 | 화면 간 데이터 공유가 필요해지는 시점에 도입 |

---

## 내 생각

### 잘 된 부분

**카카오 단일 로그인 선택은 옳다.**
구글/네이버까지 지원하면 OAuth 코드가 3배가 되고, 테스트해야 할 경우의 수도 늘어난다. 국내 서비스라면 카카오 하나로 충분하고, 구조도 훨씬 단순해진다. 처음부터 이렇게 잡은 게 맞다.

**현재 auth 패키지 구조는 Spring Boot 답다.**
Controller → Service → Repository 흐름이 명확하고, DTO 분리도 잘 되어 있다. 억지로 Clean Architecture 폴더 구조를 끼워 맞출 필요가 없다. Spring Boot가 이미 그 역할을 한다.

---

### 지금 당장 신경 써야 할 것

**Flutter가 `dart:html`에 묶여 있다는 게 가장 큰 리스크다.**
현재 Web 전용으로 고정되어 있어서 나중에 Android/iOS로 전환하려면 `dart:html` 을 쓰는 코드를 전부 교체해야 한다. `main.dart`, `login_screen.dart`, `oauth_callback_screen.dart` 세 파일이 전부 `dart:html`에 의존하고 있다. 처음부터 크로스플랫폼을 고려했다면 `flutter_secure_storage`나 `shared_preferences`를 썼을 것이다. Web만 할 거라면 지금 구조도 괜찮지만, 계획이 바뀔 가능성이 있다면 일찍 정리하는 게 낫다.

**자동 로그인 토큰 만료 체크가 없다.**
`localStorage`에 토큰이 있으면 무조건 메인 화면으로 보낸다. Access Token 유효시간이 24시간이니 하루 지나면 토큰은 만료되지만 앱은 그걸 모르고 메인으로 넘어간다. 이후 API 호출에서 401이 터지는데 현재는 그 401을 처리하는 코드가 없다. 로그인 화면이 8개 기능 화면 뒤에 숨겨져서 사용자 입장에서 혼란스럽다.

---

### 나중에 생각할 것

**PostGIS는 잘 선택했지만 지금 당장 쓸 일이 없다.**
지도/산책 기능이 구현될 때까지는 그냥 잠들어 있을 의존성이다. 급하지 않다. 단, 나중에 실제로 위치 데이터를 다루기 시작하면 공간 인덱스를 빠뜨리기 쉬운데, 그때 성능 문제가 생기고 나서 추가하면 이미 데이터가 쌓인 뒤라 마이그레이션이 번거롭다. 엔티티 설계할 때 인덱스를 같이 넣는 습관이 중요하다.

**계절 테마 시스템이 독특한데 관리 비용이 생긴다.**
현재 월별로 색상 테마가 바뀌는 구조인데, 나중에 UI 컴포넌트가 많아질수록 모든 화면이 `SeasonTheme.getColors()`를 따라야 한다는 암묵적인 규칙이 생긴다. 신규 화면을 만들 때 이 규칙을 놓치면 화면마다 색이 달라 보이는 문제가 생길 수 있다. 규칙을 문서화하거나 공통 위젯으로 강제하는 방법을 미리 생각해두는 게 좋다.
