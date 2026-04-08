# Task Card: MAP — 지도 기반 꽃 위치 표시

> **연관 PRD:** §4.1 MAP-01 ~ MAP-07  
> **우선순위:** P0 (MVP 필수)  
> **함께 읽기:** `FLOWER_CONTEXT.md` (항상 포함)

---

## 기능 요약

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| MAP-01 | 지도에 꽃 위치 마커 표시 | P0 |
| MAP-02 | 마커 클릭 시 꽃 이름/상태/사진/주소 표시 | P0 |
| MAP-03 | 현위치 기준 반경 N km 필터링 | P0 |
| MAP-04 | 꽃 종류별 필터 (벚꽃, 진달래 등) | P1 |
| MAP-07 | 마커에서 길 안내 (외부 지도 앱 연동) | P1 |

> MAP-05, MAP-06(알림)은 `tasks/NOTIFICATION/CONTEXT.md` 참고

---

## API 엔드포인트

### 3.1 주변 꽃 목록 조회
```
GET /flowers  (🔒 인증 필요)
Query: lat(필수), lng(필수), radius(기본5000m, 최대50000), species, status(before|blooming|done), cursor, limit(기본20)
→ 200: [{ flower_id, name, species, address, location:{lat,lng}, distance_m, status, bloom_start, bloom_end, thumbnail_url }]
페이지네이션: { next_cursor, has_next, limit }
```

### 3.2 꽃 상세 조회
```
GET /flowers/{flower_id}  (🔒 인증 필요)
→ 200: { flower_id, name, species, description, address, location, status, bloom_start, bloom_end, images:[], community_count }
에러: FLOWER_NOT_FOUND(404)
```

### 3.3 꽃 종류 목록 조회
```
GET /flowers/species  (🔒 인증 필요)
→ 200: [{ species, count }]
```

---

## 작업 체크리스트

- [ ] Flutter: 지도 화면 (Google Maps 또는 Naver Map SDK)
- [ ] Flutter: 꽃 마커 커스텀 아이콘
- [ ] Flutter: 마커 클릭 → 바텀시트(꽃 상세 정보)
- [ ] Flutter: 반경 필터 UI (슬라이더)
- [ ] Flutter: 꽃 종류 필터 UI (칩/드롭다운)
- [ ] Flutter: 현재 위치 권한 요청 + GPS 처리
- [ ] Flutter: 외부 지도 앱 연동 (길 안내)
- [ ] 서버: /flowers 엔드포인트 구현 (PostGIS ST_Distance)
- [ ] 서버: flowers 테이블 시드 데이터 등록
