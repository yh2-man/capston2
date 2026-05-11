package com.flower.backend.chatbot.service;

import com.flower.backend.chatbot.dto.ChatAction;
import com.flower.backend.chatbot.dto.ChatMessageRequest;
import com.flower.backend.chatbot.dto.ChatMessageResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatbotService {

    private static final int MAX_HISTORY = 12;
    private static final String SYSTEM_PROMPT = """
            당신은 꽃 산책 앱 'OurT'의 AI 도우미입니다.
            사용자가 꽃 정보, 지도 탐색, 커뮤니티 게시글, 산책 기록에 대해 질문하면 친절하게 도와주세요.
            한국어로 간결하게 답변하세요.
            앱 내 화면으로 이동이 필요하면 답변 마지막에 다음 형식으로 표시하세요:
            [ACTION:MAP] - 지도 화면
            [ACTION:COMMUNITY] - 커뮤니티 화면
            [ACTION:FLOWER_BOOK] - 꽃 도감 화면
            [ACTION:WALK] - 산책 기록 화면
            """;

    private final ChatClient.Builder chatClientBuilder;
    // 세션별 대화 기록 (sessionId → messages)
    private final ConcurrentHashMap<String, List<Message>> sessions = new ConcurrentHashMap<>();

    public ChatMessageResponse chat(ChatMessageRequest request) {
        String sessionId = request.getSessionId() != null ? request.getSessionId() : java.util.UUID.randomUUID().toString();
        List<Message> history = sessions.computeIfAbsent(sessionId, k -> new ArrayList<>());

        history.add(new UserMessage(request.getMessage()));
        if (history.size() > MAX_HISTORY) {
            history.subList(0, history.size() - MAX_HISTORY).clear();
        }

        List<Message> messages = new ArrayList<>();
        messages.add(new SystemMessage(SYSTEM_PROMPT));
        messages.addAll(history);

        String rawReply;
        try {
            rawReply = chatClientBuilder.build()
                    .prompt()
                    .messages(messages)
                    .call()
                    .content();
        } catch (Exception e) {
            log.error("OpenAI 호출 실패", e);
            rawReply = "죄송합니다, 잠시 후 다시 시도해 주세요.";
        }

        history.add(new AssistantMessage(rawReply));

        List<ChatAction> actions = parseActions(rawReply);
        String cleanReply = rawReply.replaceAll("\\[ACTION:[A-Z_]+]", "").trim();
        ChatAction primaryAction = actions.isEmpty() ? null : actions.get(0);

        return ChatMessageResponse.builder()
                .reply(cleanReply)
                .action(primaryAction)
                .actions(actions.isEmpty() ? null : actions)
                .sessionId(sessionId)
                .build();
    }

    public void clearSession(String sessionId) {
        sessions.remove(sessionId);
    }

    private List<ChatAction> parseActions(String text) {
        List<ChatAction> actions = new ArrayList<>();
        var matcher = java.util.regex.Pattern.compile("\\[ACTION:([A-Z_]+)]").matcher(text);
        while (matcher.find()) {
            String target = matcher.group(1);
            actions.add(ChatAction.builder()
                    .type("NAVIGATE")
                    .target(target)
                    .params(buildParams(target, text))
                    .build());
        }
        return actions;
    }

    private Map<String, Object> buildParams(String target, String text) {
        if ("MAP".equals(target)) {
            // 텍스트에서 검색 키워드 추출 시도
            var m = java.util.regex.Pattern.compile("'([^']{2,20})'").matcher(text);
            if (m.find()) {
                return Map.of("query", m.group(1));
            }
        }
        return null;
    }
}
