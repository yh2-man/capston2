package com.flower.backend.chatbot;

import com.flower.backend.chatbot.dto.ChatMessageRequest;
import com.flower.backend.chatbot.dto.ChatMessageResponse;
import com.flower.backend.chatbot.service.ChatbotService;
import com.flower.backend.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService chatbotService;

    @PostMapping("/message")
    public ApiResponse<ChatMessageResponse> message(@Valid @RequestBody ChatMessageRequest request) {
        return ApiResponse.ok(chatbotService.chat(request));
    }

    @DeleteMapping("/session/{sessionId}")
    public ApiResponse<Void> clearSession(@PathVariable String sessionId) {
        chatbotService.clearSession(sessionId);
        return ApiResponse.ok(null);
    }
}
