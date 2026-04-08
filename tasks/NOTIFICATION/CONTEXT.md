# Task Card: NOTIFICATION — 푸시 알림

> **연관 PRD:** §4.1 MAP-05, MAP-06  
> **우선순위:** P0 (MAP-05), P1 (MAP-06)  
> **함께 읽기:** `FLOWER_CONTEXT.md` (항상 포함)  
> **연관 기능:** `tasks/MAP/CONTEXT.md` (꽃 위치 데이터 사용)

---

## 기능 요약

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| MAP-05 | 꽃 위치 반경(기본 500m) 진입 시 푸시 알림 발송 | P0 |
| MAP-06 | 알림 ON/OFF, 반경 조정 설정 | P1 |

---

## 알림 로직

```
[사용자 GPS 위치 갱신]
       ↓
[서버에 위치 전송]
       ↓
[DB 내 꽃 위치와 거리 계산 (PostGIS ST_Distance)]
       ↓
[설정 반경(기본 500m) 이내 꽃 존재?]
    YES ↓
[해당 꽃에 대해 오늘 이미 알림 발송?]
    NO  ↓
[FCM 푸시 알림 발송]
```

---

## API 엔드포인트

### 4.1 FCM 토큰 등록/갱신
```
POST /notifications/token  (🔒 인증 필요)
Body: { fcm_token, platform: "ios" | "android" }
→ 200: { data: null }
```

### 4.2 알림 설정 조회
```
GET /notifications/settings  (🔒 인증 필요)
→ 200: { enabled, radius_m }
```

### 4.3 알림 설정 변경
```
PATCH /notifications/settings  (🔒 인증 필요)
Body: { enabled, radius_m (100~5000) }
→ 200: { enabled, radius_m }
에러: INVALID_RADIUS_RANGE(400)
```

### 4.4 꽃 접근 감지 및 알림 트리거
```
POST /notifications/location-check  (🔒 인증 필요)
Body: { lat, lng }
→ 200: { triggered, flowers_nearby: [{ flower_id, name, distance_m }] }
```

> `triggered: false`이면 알림 미발송. 당일 이미 알림 발송된 꽃은 제외.

---

## 작업 체크리스트

- [ ] Flutter: FCM 초기화 + 토큰 등록
- [ ] Flutter: 백그라운드 위치 추적 (주기적 서버 전송)
- [ ] Flutter: 알림 수신 시 앱 내 화면 이동
- [ ] Flutter: 설정 화면 (알림 ON/OFF, 반경 슬라이더)
- [ ] 서버: /notifications/* 엔드포인트 구현
- [ ] 서버: FCM 토큰 저장 테이블
- [ ] 서버: 꽃 접근 감지 로직 (PostGIS + 당일 중복 체크)
- [ ] 서버: FCM 메시지 발송 로직
