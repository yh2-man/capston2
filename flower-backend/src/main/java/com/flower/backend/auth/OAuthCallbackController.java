package com.flower.backend.auth;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class OAuthCallbackController {

    @GetMapping(value = "/oauth/callback", produces = "text/html")
    public ResponseEntity<String> kakaoCallback(@RequestParam String code) {
        String deepLink = "ourt://oauth?code=" + code;
        String html = "<!DOCTYPE html><html><head>"
            + "<meta http-equiv='refresh' content='0;url=" + deepLink + "'>"
            + "</head><body>"
            + "<script>window.location.href='" + deepLink + "';</script>"
            + "<p>앱으로 이동 중...</p>"
            + "</body></html>";
        return ResponseEntity.ok()
            .header("ngrok-skip-browser-warning", "true")
            .body(html);
    }
}
