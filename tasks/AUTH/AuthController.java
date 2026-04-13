// [기능 ID: AUTH-01~06] [명세 근거: API Spec §2.1~2.6]
package com.flower.backend.auth;

import com.flower.backend.auth.AuthDto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    // POST /api/v1/auth/signup — 일반 회원가입
    @PostMapping("/signup")
    public ResponseEntity<?> signup(@Valid @RequestBody SignupRequest request) {
        LoginResponse response = authService.signup(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(success(response));
    }

    // POST /api/v1/auth/login — 일반(LOCAL) 로그인
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(success(response));
    }

    // POST /api/v1/auth/refresh — Access Token 재발급
    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@Valid @RequestBody RefreshRequest request) {
        RefreshResponse response = authService.refresh(request);
        return ResponseEntity.ok(success(response));
    }

    // POST /api/v1/auth/nickname — 소셜 신규 유저 닉네임 설정
    @PostMapping("/nickname")
    public ResponseEntity<?> setNickname(@Valid @RequestBody NicknameRequest request) {
        LoginResponse response = authService.setNickname(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(success(response));
    }

    // ─── 예외 처리: AuthException → 표준 에러 응답 ──────────────────────
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<?> handleAuthException(AuthException e) {
        int statusCode = switch (e.getErrorCode()) {
            case "EMAIL_ALREADY_EXISTS", "NICKNAME_ALREADY_EXISTS" -> 409;
            case "INVALID_CREDENTIALS", "INVALID_REFRESH_TOKEN", "TEMP_TOKEN_EXPIRED" -> 401;
            default -> 400;
        };
        return ResponseEntity.status(statusCode).body(error(e.getErrorCode(), e.getMessage()));
    }

    // ─── 공통 응답 포맷 헬퍼 ─────────────────────────────────────────────
    // 성공: { "success": true, "data": {...} }
    private Map<String, Object> success(Object data) {
        return Map.of("success", true, "data", data);
    }

    // 실패: { "success": false, "error": { "code": "...", "message": "..." } }
    private Map<String, Object> error(String code, String message) {
        return Map.of("success", false, "error", Map.of("code", code, "message", message));
    }
}
