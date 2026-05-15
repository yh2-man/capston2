# 지도 핀 표시 + 지연 기능 구현 계획

## 1. DB 변경

```sql
-- community_posts에 지연 시간 컬럼 추가
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS map_display_delay INT NOT NULL DEFAULT 0;
  -- 0 = 즉시, 1~120 = N분 후 지도 표시 (분 단위)
```

---

## 2. 백엔드

### 2-1. CommunityPost 엔티티
```java
@Column(name = "map_display_delay", nullable = false)
private int mapDisplayDelay = 0;
```

### 2-2. 새 엔드포인트
```
GET /api/v1/flowers/spots?lat=&lng=&radius=
```
- FLOWER_SPOT 게시글 중
  - `latitude IS NOT NULL`
  - `created_at + mapDisplayDelay분 <= 현재시각`
  - 반경 내
- 반환 형식: app.js normalizeFlowers 호환

### 2-3. FlowerSpotController / CommunityService
- `createFlowerSpot()` 파라미터에 `mapDisplayDelay` 추가
- `getFlowerSpots()` 위치/시간 필터 추가

### 2-4. SecurityConfig
- `GET /api/v1/flowers/spots` → permitAll

---

## 3. Flutter

### 3-1. CreateFlowerSpotScreen 수정
위치 공유 ON일 때 지연 설정 UI 추가:

```
📍 현재 위치 공유  [ON]

🕐 지도 표시 시점
   ○ 즉시
   ● 직접 설정

   ──────[●]──────  [ 30 ] 분
   0              120
```

- 슬라이더: 0~120분, 10분 단위 스냅
- 숫자 입력: 0~120 자유 입력, 연동
- 즉시 선택 시 슬라이더/입력 비활성화

### 3-2. FlowerSpotApiService 수정
- `createFlowerSpot()` → `mapDisplayDelay` 파라미터 추가

### 3-3. app.js 수정
```javascript
// 기존 (없는 API)
fetch(`${baseUrl}/flowers?lat=...`)

// 변경 (있는 API)
fetch(`${baseUrl}/api/v1/flowers/spots?lat=...`)
```
- `normalizeFlowers()` 반환 형식 유지

---

## 4. 알림 (추후)
- 게시글 작성 시 `mapDisplayDelay`분 후 FCM 스케줄링
- 반경 내 알림 수신 동의 사용자에게 발송

---

## 5. 구현 순서
1. DB SQL 실행 (Supabase)
2. 백엔드 - 엔티티, 서비스, 엔드포인트
3. app.js - API URL 변경
4. Flutter - 지연 UI 추가
5. 알림은 별도 작업
