# API 명세서 — FLOWER 꽃 정보 모바일 앱

> **문서 버전:** v1.1  
> **작성일:** 2026-04-07  
> **최종 수정:** 2026-04-07 — 소셜 로그인 API 추가  
> **근거 문서:** PRD v1.2  
> **작성 주체:** Claude (기획 AI)  
> **구현 주체:** Claude Code  
> **베이스 URL:** `https://api.FLOWER.app/api/v1`

---

## 목차

1. [공통 규칙](#1-공통-규칙)
2. [인증 API](#2-인증-api)
3. [꽃 위치 API](#3-꽃-위치-api)
4. [알림 API](#4-알림-api)
5. [챗봇 API](#5-챗봇-api)
6. [커뮤니티 API](#6-커뮤니티-api)
7. [에러 코드 정의](#7-에러-코드-정의)

> **2. 인증 API** 에 **2.5 소셜 로그인**, **2.6 닉네임 설정** 진행 변경 반영

---

## 1. 공통 규칙

### 1.1 요청 헤더

모든 API 요청에 아래 헤더를 포함한다.

| 헤더 | 필수 여부 | 값 예시 | 설명 |
|------|-----------|---------|------|
| `Content-Type` | 필수 | `application/json` | 요청 바디 형식 |
| `Authorization` | 인증 필요 시 | `Bearer {access_token}` | JWT 액세스 토큰 |
| `Accept-Language` | 선택 | `ko` | 응답 언어 (기본값: ko) |

### 1.2 응답 공통 구조

**성공 응답**
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-04-07T12:00:00Z"
  }
}
```

**실패 응답**
```json
{
  "success": false,
  "error": {
    "code": "FLOWER_NOT_FOUND",
    "message": "해당 꽃 정보를 찾을 수 없습니다.",
    "detail": "flower_id: abc123"
  },
  "meta": {
    "timestamp": "2026-04-07T12:00:00Z"
  }
}
```

### 1.3 페이지네이션

목록 조회 API는 커서 기반 페이지네이션을 사용한다.

**요청 파라미터**
| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `cursor` | string | (없으면 첫 페이지) | 이전 응답의 `next_cursor` 값 |
| `limit` | integer | `20` | 한 페이지 최대 항목 수 (최대 100) |

**응답 예시**
```json
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "timestamp": "2026-04-07T12:00:00Z",
    "pagination": {
      "next_cursor": "eyJpZCI6IjEyMyJ9",
      "has_next": true,
      "limit": 20
    }
  }
}
```

### 1.4 HTTP 상태 코드

| 코드 | 의미 |
|------|------|
| `200` | 성공 |
| `201` | 생성 성공 |
| `400` | 잘못된 요청 (파라미터 오류) |
| `401` | 인증 실패 (토큰 없음 또는 만료) |
| `403` | 권한 없음 |
| `404` | 리소스 없음 |
| `409` | 중복 (이미 존재하는 리소스) |
| `500` | 서버 내부 오류 |

---

## 2. 인증 API

### 2.1 회원가입

```
POST /auth/signup
인증 불필요
```

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "string (8자 이상, 영문+숫자 혼합)",
  "nickname": "string (2~10자)"
}
```

**Response `201`**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "nickname": "꽃사랑",
    "created_at": "2026-04-07T12:00:00Z"
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 이미 가입된 이메일 | 409 | `EMAIL_ALREADY_EXISTS` |
| 이메일 형식 오류 | 400 | `INVALID_EMAIL_FORMAT` |
| 비밀번호 정책 미충족 | 400 | `INVALID_PASSWORD_FORMAT` |

---

### 2.2 로그인

```
POST /auth/login
인증 불필요
```

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "string"
}
```

**Response `200`**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 3600,
    "user": {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "nickname": "꽃사랑"
    }
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 이메일 또는 비밀번호 불일치 | 401 | `INVALID_CREDENTIALS` |

---

### 2.3 토큰 갱신

```
POST /auth/refresh
인증 불필요
```

**Request Body**
```json
{
  "refresh_token": "eyJhbGci..."
}
```

**Response `200`**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGci...",
    "expires_in": 3600
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| refresh_token 만료 또는 유효하지 않음 | 401 | `INVALID_REFRESH_TOKEN` |

---

### 2.4 로그아웃

```
POST /auth/logout
🔒 인증 필요
```

**Request Body**
```json
{
  "refresh_token": "eyJhbGci..."
}
```

**Response `200`**
```json
{
  "success": true,
  "data": null
}
```

---

### 2.5 소셜 로그인 (OAuth)

> **연관 PRD:** AUTH-02, AUTH-03, AUTH-04

앱에서 소셜 SDK로 보급받은 Authorization Code를 서버에 전달하면, 서버가 소셜 제공자에서 사용자 정보를 조회하고 JWT를 발급한다. 신규 사용자라면 계정을 자동 생성한다.

```
POST /auth/oauth/{provider}
인증 불필요
```

**Path Parameters**
| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `provider` | string | 소셜 제공자 (`kakao` — 현재 단일 지원) |

**Request Body**
```json
{
  "auth_code": "4/0AX4XfWh...",
  "redirect_uri": "com.flower.app://oauth"
}
```

> - `auth_code`: 았 SDK에서 소셜 제공자로부터 얻은 Authorization Code
> - `redirect_uri`: OAuth 등록 시 설정한 콜백 URI와 동일해야 함

**Response `200` — 기존 회원**
```json
{
  "success": true,
  "data": {
    "is_new_user": false,
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 3600,
    "user": {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "nickname": "꽃사랑"
    }
  }
}
```

**Response `200` — 신규 회원 (최초 소셜 로그인)**
```json
{
  "success": true,
  "data": {
    "is_new_user": true,
    "temp_token": "eyJhbGci...",
    "provider": "kakao",
    "provider_email": "user@kakao.com"
  }
}
```

> `is_new_user: true`이면 닉네임 미설정 상태. 앱은 `2.6 닉네임 설정` API를 호출해야 한다.

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 유효하지 않은 auth_code | 401 | `INVALID_OAUTH_CODE` |
| 지원하지 않는 provider | 400 | `UNSUPPORTED_OAUTH_PROVIDER` |
| 소셜 제공자 서버 오류 | 500 | `OAUTH_UPSTREAM_ERROR` |

---

### 2.6 닉네임 설정 (신규 소셜 회원 전용)

> **연관 PRD:** AUTH-05

소셜 로그인 최초 가입 시 `is_new_user: true`를 받은 신규 사용자가 닉네임을 설정한다.

```
POST /auth/nickname
인증 불필요 (temp_token으로 인증)
```

**Request Body**
```json
{
  "temp_token": "eyJhbGci...",
  "nickname": "꽃사랑"
}
```

> - `temp_token`: `2.5` 에서 신규 회원에게 발급된 임시 토큰 (유효시간 10분)
> - `nickname`: 2~10자

**Response `201`**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "eyJhbGci...",
    "expires_in": 3600,
    "user": {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "nickname": "꽃사랑"
    }
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| temp_token 만료 | 401 | `TEMP_TOKEN_EXPIRED` |
| 닉네임 중복 | 409 | `NICKNAME_ALREADY_EXISTS` |
| 닉네임 길이 초과 | 400 | `INVALID_NICKNAME_LENGTH` |

---

## 3. 꽃 위치 API

> **연관 PRD:** §4.1 MAP-01 ~ MAP-07

### 3.1 주변 꽃 목록 조회

사용자 현재 위치 기반으로 반경 내 꽃 목록을 반환한다. (PostGIS ST_Distance 사용)

```
GET /flowers
🔒 인증 필요
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| `lat` | float | ✅ | - | 사용자 위도 (예: 37.5665) |
| `lng` | float | ✅ | - | 사용자 경도 (예: 126.9780) |
| `radius` | integer | ❌ | `5000` | 검색 반경 (미터, 최대 50000) |
| `species` | string | ❌ | - | 꽃 종류 필터 (예: `벚꽃`, `수국`) |
| `status` | string | ❌ | - | 개화 상태 필터 (`before`, `blooming`, `done`) |
| `cursor` | string | ❌ | - | 페이지네이션 커서 |
| `limit` | integer | ❌ | `20` | 한 페이지 항목 수 |

**Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "flower_id": "f1a2b3c4-...",
      "name": "여의도 벚꽃길",
      "species": "벚꽃",
      "address": "서울특별시 영등포구 여의동",
      "location": {
        "lat": 37.5285,
        "lng": 126.9326
      },
      "distance_m": 320,
      "status": "blooming",
      "bloom_start": "2026-03-28",
      "bloom_end": "2026-04-10",
      "thumbnail_url": "https://storage.FLOWER.app/flowers/f1a2b3c4.jpg"
    }
  ],
  "meta": {
    "timestamp": "2026-04-07T12:00:00Z",
    "pagination": {
      "next_cursor": "eyJpZCI6IjEyMyJ9",
      "has_next": true,
      "limit": 20
    }
  }
}
```

---

### 3.2 꽃 상세 조회

```
GET /flowers/{flower_id}
🔒 인증 필요
```

**Path Parameters**
| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `flower_id` | string (UUID) | 꽃 ID |

**Response `200`**
```json
{
  "success": true,
  "data": {
    "flower_id": "f1a2b3c4-...",
    "name": "여의도 벚꽃길",
    "species": "벚꽃",
    "description": "한강 변을 따라 이어지는 1.7km 벚꽃 산책로",
    "address": "서울특별시 영등포구 여의동",
    "location": {
      "lat": 37.5285,
      "lng": 126.9326
    },
    "status": "blooming",
    "bloom_start": "2026-03-28",
    "bloom_end": "2026-04-10",
    "images": [
      "https://storage.FLOWER.app/flowers/f1a2b3c4_1.jpg",
      "https://storage.FLOWER.app/flowers/f1a2b3c4_2.jpg"
    ],
    "community_count": 42
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 존재하지 않는 flower_id | 404 | `FLOWER_NOT_FOUND` |

---

### 3.3 꽃 종류 목록 조회

필터에 사용할 수 있는 전체 꽃 종류 목록을 반환한다.

```
GET /flowers/species
🔒 인증 필요
```

**Response `200`**
```json
{
  "success": true,
  "data": [
    { "species": "벚꽃", "count": 128 },
    { "species": "진달래", "count": 74 },
    { "species": "수국", "count": 53 },
    { "species": "코스모스", "count": 41 }
  ]
}
```

---

## 4. 알림 API

> **연관 PRD:** §4.1 MAP-05, MAP-06

### 4.1 FCM 토큰 등록 / 갱신

앱 실행 시 FCM 토큰을 서버에 등록한다. 기존 토큰이 있으면 갱신한다.

```
POST /notifications/token
🔒 인증 필요
```

**Request Body**
```json
{
  "fcm_token": "fcm_token_string",
  "platform": "ios"
}
```

> `platform`: `ios` 또는 `android`

**Response `200`**
```json
{
  "success": true,
  "data": null
}
```

---

### 4.2 알림 설정 조회

```
GET /notifications/settings
🔒 인증 필요
```

**Response `200`**
```json
{
  "success": true,
  "data": {
    "enabled": true,
    "radius_m": 500
  }
}
```

---

### 4.3 알림 설정 변경

```
PATCH /notifications/settings
🔒 인증 필요
```

**Request Body**
```json
{
  "enabled": true,
  "radius_m": 1000
}
```

> `radius_m` 허용 범위: 100 ~ 5000 (미터)

**Response `200`**
```json
{
  "success": true,
  "data": {
    "enabled": true,
    "radius_m": 1000
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| radius_m 범위 초과 | 400 | `INVALID_RADIUS_RANGE` |

---

### 4.4 꽃 접근 감지 및 알림 트리거

앱이 백그라운드에서 주기적으로 위치를 서버에 전송하면, 서버가 반경 내 꽃 존재 여부를 판단하고 FCM 알림을 발송한다.

```
POST /notifications/location-check
🔒 인증 필요
```

**Request Body**
```json
{
  "lat": 37.5285,
  "lng": 126.9326
}
```

**Response `200`**
```json
{
  "success": true,
  "data": {
    "triggered": true,
    "flowers_nearby": [
      {
        "flower_id": "f1a2b3c4-...",
        "name": "여의도 벚꽃길",
        "distance_m": 320
      }
    ]
  }
}
```

> `triggered: false`이면 알림 미발송. 당일 이미 알림이 발송된 꽃은 `flowers_nearby`에서 제외된다.

---

## 5. 챗봇 API

> **연관 PRD:** §4.2 BOT-01 ~ BOT-06

### 5.1 챗봇 메시지 전송

사용자의 텍스트 메시지를 서버로 전송하면, 인텐트 분류 후 라우팅 정보와 RAG 답변을 반환한다.

```
POST /chatbot/message
🔒 인증 필요
```

**Request Body**
```json
{
  "message": "근처에 벚꽃 보러 가고 싶어",
  "session_id": "sess_abc123",
  "context": {
    "lat": 37.5665,
    "lng": 126.9780
  }
}
```

> - `session_id`: 대화 세션 유지용. 첫 요청 시 클라이언트가 UUID 생성.
> - `context.lat`, `context.lng`: 위치 기반 답변에 사용 (선택).

**Response `200`**
```json
{
  "success": true,
  "data": {
    "intent": "INTENT-MAP",
    "reply": "근처에 벚꽃 명소를 찾아볼게요! 지도 화면으로 이동합니다.",
    "action": {
      "type": "NAVIGATE",
      "target": "MAP",
      "params": {
        "species": "벚꽃",
        "lat": 37.5665,
        "lng": 126.9780,
        "radius": 5000
      }
    }
  }
}
```

**인텐트별 action 구조**

| intent | action.type | action.target | action.params |
|--------|-------------|---------------|---------------|
| `INTENT-MAP` | `NAVIGATE` | `MAP` | `species`, `lat`, `lng`, `radius` |
| `INTENT-COMMUNITY` | `NAVIGATE` | `COMMUNITY` | - |
| `INTENT-INFO` | `ANSWER` | - | - (reply에 RAG 답변 포함) |
| `INTENT-UNKNOWN` | `RETRY` | - | - |

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| message가 빈 문자열 | 400 | `EMPTY_MESSAGE` |
| OpenAI API 오류 | 500 | `CHATBOT_UPSTREAM_ERROR` |

---

### 5.2 음성 메시지 전송 (STT)

음성 파일을 서버로 업로드하면 STT 변환 후 5.1과 동일한 처리를 수행한다.

```
POST /chatbot/voice
🔒 인증 필요
Content-Type: multipart/form-data
```

**Request Form Data**
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `audio` | file | ✅ | 음성 파일 (m4a, wav, mp3, 최대 10MB) |
| `session_id` | string | ✅ | 대화 세션 ID |
| `lat` | float | ❌ | 사용자 위도 |
| `lng` | float | ❌ | 사용자 경도 |

**Response `200`**
```json
{
  "success": true,
  "data": {
    "transcribed_text": "근처에 벚꽃 보러 가고 싶어",
    "intent": "INTENT-MAP",
    "reply": "근처에 벚꽃 명소를 찾아볼게요! 지도 화면으로 이동합니다.",
    "action": {
      "type": "NAVIGATE",
      "target": "MAP",
      "params": {
        "species": "벚꽃",
        "lat": 37.5665,
        "lng": 126.9780,
        "radius": 5000
      }
    }
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 지원하지 않는 파일 형식 | 400 | `UNSUPPORTED_AUDIO_FORMAT` |
| 파일 크기 초과 | 400 | `AUDIO_FILE_TOO_LARGE` |
| STT 변환 실패 | 500 | `STT_CONVERSION_FAILED` |

---

### 5.3 대화 세션 초기화

```
DELETE /chatbot/session/{session_id}
🔒 인증 필요
```

**Path Parameters**
| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `session_id` | string | 초기화할 세션 ID |

**Response `200`**
```json
{
  "success": true,
  "data": null
}
```

---

## 6. 커뮤니티 API

> **연관 PRD:** §4.3 COMM-01 ~ COMM-07

### 6.1 게시글 목록 조회

```
GET /posts
🔒 인증 필요
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| `sort` | string | ❌ | `latest` | 정렬 방식 (`latest`, `popular`) |
| `flower_id` | string | ❌ | - | 특정 꽃 위치의 게시글만 조회 |
| `species` | string | ❌ | - | 특정 꽃 종류의 게시글만 조회 |
| `cursor` | string | ❌ | - | 페이지네이션 커서 |
| `limit` | integer | ❌ | `20` | 한 페이지 항목 수 |

**Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "post_id": "p1a2b3c4-...",
      "user": {
        "user_id": "u1a2b3c4-...",
        "nickname": "꽃사랑"
      },
      "flower": {
        "flower_id": "f1a2b3c4-...",
        "name": "여의도 벚꽃길",
        "species": "벚꽃"
      },
      "content": "오늘 여의도 벚꽃 만개했어요!",
      "image_url": "https://storage.FLOWER.app/posts/p1a2b3c4.jpg",
      "likes_count": 23,
      "comments_count": 5,
      "is_liked": false,
      "created_at": "2026-04-07T10:30:00Z"
    }
  ],
  "meta": {
    "timestamp": "2026-04-07T12:00:00Z",
    "pagination": {
      "next_cursor": "eyJpZCI6IjQ1NiJ9",
      "has_next": true,
      "limit": 20
    }
  }
}
```

---

### 6.2 게시글 상세 조회

```
GET /posts/{post_id}
🔒 인증 필요
```

**Path Parameters**
| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `post_id` | string (UUID) | 게시글 ID |

**Response `200`**
```json
{
  "success": true,
  "data": {
    "post_id": "p1a2b3c4-...",
    "user": {
      "user_id": "u1a2b3c4-...",
      "nickname": "꽃사랑"
    },
    "flower": {
      "flower_id": "f1a2b3c4-...",
      "name": "여의도 벚꽃길",
      "species": "벚꽃",
      "location": { "lat": 37.5285, "lng": 126.9326 }
    },
    "content": "오늘 여의도 벚꽃 만개했어요!",
    "image_url": "https://storage.FLOWER.app/posts/p1a2b3c4.jpg",
    "location": { "lat": 37.5285, "lng": 126.9326 },
    "likes_count": 23,
    "comments_count": 5,
    "is_liked": false,
    "created_at": "2026-04-07T10:30:00Z"
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 존재하지 않는 post_id | 404 | `POST_NOT_FOUND` |

---

### 6.3 게시글 작성

```
POST /posts
🔒 인증 필요
Content-Type: multipart/form-data
```

**Request Form Data**
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `image` | file | ✅ | 사진 (jpg, png, webp, 최대 10MB) |
| `content` | string | ✅ | 본문 텍스트 (최대 500자) |
| `flower_id` | string | ❌ | 연관 꽃 ID |
| `lat` | float | ❌ | 게시글 위치 위도 |
| `lng` | float | ❌ | 게시글 위치 경도 |

**Response `201`**
```json
{
  "success": true,
  "data": {
    "post_id": "p9z8y7x6-...",
    "image_url": "https://storage.FLOWER.app/posts/p9z8y7x6.jpg",
    "content": "오늘 여의도 벚꽃 만개했어요!",
    "created_at": "2026-04-07T12:00:00Z"
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 이미지 없음 | 400 | `IMAGE_REQUIRED` |
| 파일 형식 오류 | 400 | `UNSUPPORTED_IMAGE_FORMAT` |
| 파일 크기 초과 | 400 | `IMAGE_FILE_TOO_LARGE` |
| content 초과 | 400 | `CONTENT_TOO_LONG` |

---

### 6.4 게시글 삭제

```
DELETE /posts/{post_id}
🔒 인증 필요
```

**Response `200`**
```json
{
  "success": true,
  "data": null
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 본인 게시글 아닌 경우 | 403 | `FORBIDDEN_POST_DELETE` |
| 존재하지 않는 post_id | 404 | `POST_NOT_FOUND` |

---

### 6.5 좋아요 등록 / 취소

```
POST   /posts/{post_id}/like    ← 좋아요 등록
DELETE /posts/{post_id}/like    ← 좋아요 취소
🔒 인증 필요
```

**Response `200`**
```json
{
  "success": true,
  "data": {
    "is_liked": true,
    "likes_count": 24
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 이미 좋아요한 게시글에 재등록 | 409 | `ALREADY_LIKED` |
| 좋아요하지 않은 게시글 취소 | 409 | `NOT_LIKED` |

---

### 6.6 댓글 목록 조회

```
GET /posts/{post_id}/comments
🔒 인증 필요
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| `cursor` | string | ❌ | - | 페이지네이션 커서 |
| `limit` | integer | ❌ | `20` | 한 페이지 항목 수 |

**Response `200`**
```json
{
  "success": true,
  "data": [
    {
      "comment_id": "c1a2b3c4-...",
      "user": {
        "user_id": "u5e6f7g8-...",
        "nickname": "봄날산책"
      },
      "content": "저도 오늘 다녀왔어요! 정말 예뻤어요 🌸",
      "created_at": "2026-04-07T11:00:00Z"
    }
  ],
  "meta": {
    "timestamp": "2026-04-07T12:00:00Z",
    "pagination": {
      "next_cursor": null,
      "has_next": false,
      "limit": 20
    }
  }
}
```

---

### 6.7 댓글 작성

```
POST /posts/{post_id}/comments
🔒 인증 필요
```

**Request Body**
```json
{
  "content": "저도 오늘 다녀왔어요! 정말 예뻤어요 🌸"
}
```

> content 최대 200자

**Response `201`**
```json
{
  "success": true,
  "data": {
    "comment_id": "c9z8y7x6-...",
    "content": "저도 오늘 다녀왔어요! 정말 예뻤어요 🌸",
    "created_at": "2026-04-07T12:00:00Z"
  }
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 존재하지 않는 post_id | 404 | `POST_NOT_FOUND` |
| content 초과 | 400 | `CONTENT_TOO_LONG` |

---

### 6.8 댓글 삭제

```
DELETE /posts/{post_id}/comments/{comment_id}
🔒 인증 필요
```

**Response `200`**
```json
{
  "success": true,
  "data": null
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 본인 댓글 아닌 경우 | 403 | `FORBIDDEN_COMMENT_DELETE` |
| 존재하지 않는 comment_id | 404 | `COMMENT_NOT_FOUND` |

---

### 6.9 게시글 신고

```
POST /posts/{post_id}/report
🔒 인증 필요
```

**Request Body**
```json
{
  "reason": "SPAM",
  "detail": "광고성 게시글입니다."
}
```

> `reason` 허용값: `SPAM`, `INAPPROPRIATE`, `WRONG_INFO`, `OTHER`

**Response `201`**
```json
{
  "success": true,
  "data": null
}
```

**에러 케이스**
| 상황 | HTTP | error.code |
|------|------|------------|
| 이미 신고한 게시글 | 409 | `ALREADY_REPORTED` |

---

## 7. 에러 코드 정의

| error.code | HTTP | 설명 |
|------------|------|------|
| `EMAIL_ALREADY_EXISTS` | 409 | 이미 가입된 이메일 |
| `INVALID_EMAIL_FORMAT` | 400 | 이메일 형식 오류 |
| `INVALID_PASSWORD_FORMAT` | 400 | 비밀번호 정책 미충족 |
| `INVALID_CREDENTIALS` | 401 | 이메일 또는 비밀번호 불일치 |
| `INVALID_REFRESH_TOKEN` | 401 | refresh_token 만료 또는 무효 |
| `UNAUTHORIZED` | 401 | access_token 없음 또는 만료 |
| `FORBIDDEN_POST_DELETE` | 403 | 타인 게시글 삭제 시도 |
| `FORBIDDEN_COMMENT_DELETE` | 403 | 타인 댓글 삭제 시도 |
| `FLOWER_NOT_FOUND` | 404 | 존재하지 않는 꽃 ID |
| `POST_NOT_FOUND` | 404 | 존재하지 않는 게시글 ID |
| `COMMENT_NOT_FOUND` | 404 | 존재하지 않는 댓글 ID |
| `ALREADY_LIKED` | 409 | 이미 좋아요한 게시글 |
| `NOT_LIKED` | 409 | 좋아요하지 않은 게시글 취소 시도 |
| `ALREADY_REPORTED` | 409 | 이미 신고한 게시글 |
| `IMAGE_REQUIRED` | 400 | 이미지 필드 누락 |
| `UNSUPPORTED_IMAGE_FORMAT` | 400 | 지원하지 않는 이미지 형식 |
| `IMAGE_FILE_TOO_LARGE` | 400 | 이미지 파일 크기 초과 (10MB) |
| `CONTENT_TOO_LONG` | 400 | 텍스트 길이 초과 |
| `EMPTY_MESSAGE` | 400 | 챗봇 메시지 빈 문자열 |
| `UNSUPPORTED_AUDIO_FORMAT` | 400 | 지원하지 않는 오디오 형식 |
| `AUDIO_FILE_TOO_LARGE` | 400 | 오디오 파일 크기 초과 (10MB) |
| `STT_CONVERSION_FAILED` | 500 | STT 변환 실패 |
| `CHATBOT_UPSTREAM_ERROR` | 500 | OpenAI API 오류 |
| `INVALID_RADIUS_RANGE` | 400 | 알림 반경 범위 초과 |
| `INVALID_OAUTH_CODE` | 401 | 소셜 OAuth Authorization Code 무효 |
| `UNSUPPORTED_OAUTH_PROVIDER` | 400 | 지원하지 않는 소셜 제공자 |
| `OAUTH_UPSTREAM_ERROR` | 500 | 소셜 제공자 서버 오류 |
| `TEMP_TOKEN_EXPIRED` | 401 | 닉네임 설정용 임시 토큰 만료 |
| `NICKNAME_ALREADY_EXISTS` | 409 | 이미 사용 중인 닉네임 |
| `INVALID_NICKNAME_LENGTH` | 400 | 닉네임 길이 범위 초과 (2~10자) |
| `INTERNAL_SERVER_ERROR` | 500 | 서버 내부 오류 |

---

*본 문서는 Claude가 작성하였으며, PRD v1.2을 기준으로 합니다.*  
*변경 이력: v1.0 최초 작성 (2026-04-07) → v1.1 소셜 로그인 API 추가 (2026-04-07)*  
*다음 업데이트 예정: 화면 플로우 다이어그램 (v1.2)*
