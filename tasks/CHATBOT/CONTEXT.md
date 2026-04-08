# Task Card: CHATBOT — 지능형 챗봇

> **연관 PRD:** §4.2 BOT-01 ~ BOT-06  
> **우선순위:** P0 (BOT-01~04, BOT-06), P1 (BOT-05)  
> **함께 읽기:** `FLOWER_CONTEXT.md` (항상 포함)  
> **연관 기능:** `tasks/MAP/CONTEXT.md` (INTENT-MAP 시 지도 화면으로 이동)

---

## 기능 요약

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| BOT-01 | 텍스트 입력으로 챗봇 메시지 전송 | P0 |
| BOT-02 | 음성 입력으로 챗봇 메시지 전송 | P0 |
| BOT-03 | 인텐트 인식 → 해당 화면 자동 이동 | P0 |
| BOT-04 | 꽃 관련 질의에 DB 기반 RAG 답변 | P0 |
| BOT-05 | 대화 내역 세션 유지 | P1 |
| BOT-06 | 큰 글씨 모드 대응 | P0 |

---

## 외부 연동 API

| 서비스 | API 이름 | 용도 | 비고 |
| :--- | :--- | :--- | :--- |
| **OpenAI** | GPT-4o API | 의도 분류(Intent) 및 RAG 답변 생성 | 종량제 (Groq/Ollama로 개발 단계 무료 대체 가능) |
| **Google** | Cloud Speech-to-Text | 음성 명령을 텍스트로 변환 (STT) | 월 60분 무료 (Flutter 패키지로 무료 대체 가능) |

---

## 인텐트 라우팅 테이블

| intent | action.type | action.target | 실행 동작 |
|--------|-------------|---------------|-----------|
| `INTENT-MAP` | `NAVIGATE` | `MAP` | 지도 화면 이동 + 꽃 필터 자동 적용 |
| `INTENT-COMMUNITY` | `NAVIGATE` | `COMMUNITY` | 커뮤니티 화면 이동 |
| `INTENT-INFO` | `ANSWER` | - | reply에 RAG 답변 포함 |
| `INTENT-UNKNOWN` | `RETRY` | - | 재입력 안내 메시지 |

---

## API 엔드포인트

### 5.1 텍스트 메시지 전송
```
POST /chatbot/message  (🔒 인증 필요)
Body: { message, session_id, context: { lat, lng } (선택) }
→ 200: { intent, reply, action: { type, target, params } }
에러: EMPTY_MESSAGE(400), CHATBOT_UPSTREAM_ERROR(500)
```

### 5.2 음성 메시지 전송 (STT)
```
POST /chatbot/voice  (🔒 인증 필요, multipart/form-data)
Form: audio(파일, m4a/wav/mp3, 최대10MB), session_id, lat(선택), lng(선택)
→ 200: { transcribed_text, intent, reply, action }
에러: UNSUPPORTED_AUDIO_FORMAT(400), AUDIO_FILE_TOO_LARGE(400), STT_CONVERSION_FAILED(500)
```

### 5.3 대화 세션 초기화
```
DELETE /chatbot/session/{session_id}  (🔒 인증 필요)
→ 200: { data: null }
```

---

## 챗봇 처리 흐름

```
[사용자 입력 (음성/텍스트)]
       ↓
[STT 변환 (음성인 경우)]
       ↓
[OpenAI API — 인텐트 분류]
       ↓
   인텐트?
  ┌────┬────┬────┐
 MAP  COMM INFO  UNKNOWN
  ↓    ↓    ↓      ↓
 화면  화면  RAG   재입력
 이동  이동  답변   안내
```

---

## 작업 체크리스트

- [ ] Flutter: 챗봇 대화 화면 UI (메시지 버블)
- [ ] Flutter: 텍스트 입력 + 전송
- [ ] Flutter: 음성 녹음 + 파일 전송
- [ ] Flutter: action.type에 따른 화면 라우팅 처리
- [ ] Flutter: 큰 글씨 모드 대응 레이아웃
- [ ] 서버: /chatbot/* 엔드포인트 구현
- [ ] 서버: OpenAI API 연동 (인텐트 분류 프롬프트)
- [ ] 서버: RAG 파이프라인 (꽃 DB 검색 → LLM 답변)
- [ ] 서버: STT 변환 (Whisper API 등)
- [ ] 서버: 세션 관리 (Redis 또는 DB)
