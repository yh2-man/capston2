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
    private final OAuthService oAuthService;

    // 일반 회원가입/로그인 엔드포인트 제거됨 (소셜 전용)

    // POST /api/v1/auth/refresh — Access Token 재발급
    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@Valid @RequestBody RefreshRequest request) {
        RefreshResponse response = authService.refresh(request);
        return ResponseEntity.ok(success(response));
    }

    // POST /api/v1/auth/profile-setup — 소셜 신규 유저 프로필 설정
    @PostMapping("/profile-setup")
    public ResponseEntity<?> setupProfile(@Valid @RequestBody ProfileSetupRequest request) {
        LoginResponse response = authService.setupProfile(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(success(response));
    }

    // POST /api/v1/auth/oauth/google — 구글 소셜 로그인
    @PostMapping("/oauth/google")
    public ResponseEntity<?> oauthGoogle(@Valid @RequestBody AuthDto.OAuthRequest request) {
        Object response = oAuthService.processGoogle(request.getAuthCode(), request.getRedirectUri());
        return ResponseEntity.ok(success(response));
    }

    // POST /api/v1/auth/oauth/naver — 네이버 소셜 로그인
    @PostMapping("/oauth/naver")
    public ResponseEntity<?> oauthNaver(@Valid @RequestBody AuthDto.OAuthRequest request) {
        Object response = oAuthService.processNaver(request.getAuthCode(), request.getRedirectUri());
        return ResponseEntity.ok(success(response));
    }

    // POST /api/v1/auth/oauth/kakao — 카카오 소셜 로그인
    @PostMapping("/oauth/kakao")
    public ResponseEntity<?> oauthKakao(@Valid @RequestBody AuthDto.OAuthRequest request) {
        Object response = oAuthService.processKakao(request.getAuthCode(), request.getRedirectUri());
        return ResponseEntity.ok(success(response));
    }

    // POST /api/v1/auth/logout — 로그아웃 (토큰 필수)
    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        // JWT 필터에서 SecurityContext에 등록한 userId 꺼내기
        var auth = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication();
        Long userId = (Long) auth.getPrincipal();
        authService.logout(userId);
        return ResponseEntity.ok(success(null));
    }

    // ─── 예외 처리: AuthException → 표준 에러 응답 ──────────────────────
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<?> handleAuthException(AuthException e) {
        int statusCode = switch (e.getErrorCode()) {
            case "NICKNAME_ALREADY_EXISTS" -> 409;
            case "INVALID_CREDENTIALS", "INVALID_REFRESH_TOKEN", "TEMP_TOKEN_EXPIRED" -> 401;
            default -> 400;
        };
        return ResponseEntity.status(statusCode).body(error(e.getErrorCode(), e.getMessage()));
    }

    // ─── 공통 응답 포맷 헬퍼 ─────────────────────────────────────────────
    // 성공: { "success": true, "data": {...} }
    private Map<String, Object> success(Object data) {
        var map = new java.util.LinkedHashMap<String, Object>();
        map.put("success", true);
        map.put("data", data);  // data가 null이어도 허용 (Map.of는 null 불가)
        return map;
    }

    // 실패: { "success": false, "error": { "code": "...", "message": "..." } }
    private Map<String, Object> error(String code, String message) {
        return Map.of("success", false, "error", Map.of("code", code, "message", message));
    }
}
