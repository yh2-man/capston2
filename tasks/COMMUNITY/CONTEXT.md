# Task Card: COMMUNITY — 커뮤니티

> **연관 PRD:** §4.3 COMM-01 ~ COMM-07  
> **우선순위:** P1 (COMM-01~05), P2 (COMM-06~07)  
> **함께 읽기:** `FLOWER_CONTEXT.md` (항상 포함)  
> **연관 기능:** `tasks/MAP/CONTEXT.md` (flower_id로 꽃 위치 연결)

---

## 기능 요약

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| COMM-01 | 게시글 작성 (사진 + 텍스트 + 위치 태그) | P1 |
| COMM-02 | 게시글 목록 조회 (최신순, 인기순) | P1 |
| COMM-03 | 게시글 상세 조회 | P1 |
| COMM-04 | 댓글 작성 및 조회 | P1 |
| COMM-05 | 좋아요 기능 | P1 |
| COMM-06 | 게시글 신고 | P2 |
| COMM-07 | 팔로우/팔로잉 | P2 |

---

## API 엔드포인트

### 6.1 게시글 목록 조회
```
GET /posts  (🔒 인증 필요)
Query: sort(latest|popular), flower_id, species, cursor, limit(기본20)
→ 200: [{ post_id, user, flower, content, image_url, likes_count, comments_count, is_liked, created_at }]
```

### 6.2 게시글 상세 조회
```
GET /posts/{post_id}  (🔒 인증 필요)
→ 200: { post_id, user, flower, content, image_url, location, likes_count, comments_count, is_liked, created_at }
에러: POST_NOT_FOUND(404)
```

### 6.3 게시글 작성
```
POST /posts  (🔒 인증 필요, multipart/form-data)
Form: image(필수, jpg/png/webp, 최대10MB), content(필수, 최대500자), flower_id(선택), lat(선택), lng(선택)
→ 201: { post_id, image_url, content, created_at }
에러: IMAGE_REQUIRED(400), UNSUPPORTED_IMAGE_FORMAT(400), IMAGE_FILE_TOO_LARGE(400), CONTENT_TOO_LONG(400)
```

### 6.4 게시글 삭제
```
DELETE /posts/{post_id}  (🔒 인증 필요)
→ 200: { data: null }
에러: FORBIDDEN_POST_DELETE(403), POST_NOT_FOUND(404)
```

### 6.5 좋아요 등록/취소
```
POST   /posts/{post_id}/like  (🔒 인증 필요)  ← 등록
DELETE /posts/{post_id}/like  (🔒 인증 필요)  ← 취소
→ 200: { is_liked, likes_count }
에러: ALREADY_LIKED(409), NOT_LIKED(409)
```

### 6.6 댓글 목록 조회
```
GET /posts/{post_id}/comments  (🔒 인증 필요)
Query: cursor, limit(기본20)
→ 200: [{ comment_id, user, content, created_at }]
```

### 6.7 댓글 작성
```
POST /posts/{post_id}/comments  (🔒 인증 필요)
Body: { content (최대200자) }
→ 201: { comment_id, content, created_at }
에러: POST_NOT_FOUND(404), CONTENT_TOO_LONG(400)
```

### 6.8 댓글 삭제
```
DELETE /posts/{post_id}/comments/{comment_id}  (🔒 인증 필요)
→ 200: { data: null }
에러: FORBIDDEN_COMMENT_DELETE(403), COMMENT_NOT_FOUND(404)
```

### 6.9 게시글 신고
```
POST /posts/{post_id}/report  (🔒 인증 필요)
Body: { reason: SPAM|INAPPROPRIATE|WRONG_INFO|OTHER, detail (선택) }
→ 201: { data: null }
에러: ALREADY_REPORTED(409)
```

---

## 작업 체크리스트

- [ ] Flutter: 게시글 목록 화면 (최신순/인기순 탭)
- [ ] Flutter: 게시글 상세 화면 (사진 + 댓글)
- [ ] Flutter: 게시글 작성 화면 (카메라/갤러리 + 텍스트 + 꽃 태그)
- [ ] Flutter: 좋아요 버튼 (토글 + 카운트 애니메이션)
- [ ] Flutter: 댓글 입력 + 목록
- [ ] Flutter: 신고 다이얼로그
- [ ] 서버: /posts/* 엔드포인트 구현
- [ ] 서버: 이미지 업로드 → S3/Firebase Storage
- [ ] 서버: posts, comments 테이블 CRUD
- [ ] 서버: 좋아요 테이블 (user_id + post_id 유니크 제약)
- [ ] 서버: 신고 테이블 (중복 신고 방지)
