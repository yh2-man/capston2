// [기능 ID: AUTH-02,04] [명세 근거: PRD §4.0 / API Spec §2.5]
package com.flower.backend.auth;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

/**
 * 구글/네이버 OAuth 서버와의 실제 HTTP 통신을 담당하는 서비스.
 *
 * 흐름:
 * 1. Flutter 앱 → (auth_code + redirect_uri) → 우리 서버
 * 2. 우리 서버 → (auth_code로 소셜 서버에 Access Token 요청)
 * 3. 우리 서버 → (소셜 Access Token으로 유저 프로필 조회)
 * 4. 조회한 이메일/닉네임 → AuthService.processOAuth() 에 전달
 */
@Slf4j
@Service
public class OAuthService {

    private final OAuthProperties oAuthProperties;
    private final AuthService authService;
    private final RestTemplate restTemplate;

    // RestTemplate을 생성자로 주입받아 테스트 시 MockRestServiceServer 연결 가능
    public OAuthService(OAuthProperties oAuthProperties, AuthService authService, RestTemplate restTemplate) {
        this.oAuthProperties = oAuthProperties;
        this.authService = authService;
        this.restTemplate = restTemplate;
    }

    // ─── 구글 OAuth 처리 ─────────────────────────────────────────────────

    public Object processGoogle(String authCode, String redirectUri) {
        // 1단계: auth_code → Google Access Token 교환
        String googleAccessToken = getGoogleAccessToken(authCode, redirectUri);

        // 2단계: Google Access Token → 유저 정보 조회
        GoogleUserInfo userInfo = getGoogleUserInfo(googleAccessToken);

        log.info("[OAuth] 구글 로그인 시도 - email: {}", userInfo.getEmail());

        // 3단계: 기존 회원이면 로그인, 신규면 닉네임 설정 화면으로 안내
        return authService.processOAuth(
            userInfo.getEmail(),
            userInfo.getName(),
            User.Provider.GOOGLE,
            userInfo.getId()
        );
    }

    private String getGoogleAccessToken(String authCode, String redirectUri) {
        String tokenUrl = "https://oauth2.googleapis.com/token";

        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("code", authCode);
        params.add("client_id", oAuthProperties.getGoogle().getClientId());
        params.add("client_secret", oAuthProperties.getGoogle().getClientSecret());
        params.add("redirect_uri", redirectUri);
        params.add("grant_type", "authorization_code");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        ResponseEntity<GoogleTokenResponse> response = restTemplate.postForEntity(
            tokenUrl, new HttpEntity<>(params, headers), GoogleTokenResponse.class
        );

        if (response.getBody() == null || response.getBody().getAccessToken() == null) {
            throw new AuthException("INVALID_OAUTH_CODE", "구글 토큰 발급에 실패했습니다.");
        }
        return response.getBody().getAccessToken();
    }

    private GoogleUserInfo getGoogleUserInfo(String accessToken) {
        String userInfoUrl = "https://www.googleapis.com/oauth2/v2/userinfo";

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);

        ResponseEntity<GoogleUserInfo> response = restTemplate.exchange(
            userInfoUrl, HttpMethod.GET, new HttpEntity<>(headers), GoogleUserInfo.class
        );

        if (response.getBody() == null) {
            throw new AuthException("OAUTH_UPSTREAM_ERROR", "구글 유저 정보 조회에 실패했습니다.");
        }
        return response.getBody();
    }

    // ─── 네이버 OAuth 처리 ───────────────────────────────────────────────

    public Object processNaver(String authCode, String redirectUri) {
        // 1단계: auth_code → Naver Access Token 교환
        String naverAccessToken = getNaverAccessToken(authCode, redirectUri);

        // 2단계: Naver Access Token → 유저 정보 조회
        NaverUserInfo userInfo = getNaverUserInfo(naverAccessToken);

        log.info("[OAuth] 네이버 로그인 시도 - email: {}", userInfo.getEmail());

        // 3단계: 기존 회원이면 로그인, 신규면 닉네임 설정 화면으로 안내
        return authService.processOAuth(
            userInfo.getEmail(),
            userInfo.getNickname(),
            User.Provider.NAVER,
            userInfo.getId()
        );
    }

    private String getNaverAccessToken(String authCode, String redirectUri) {
        String tokenUrl = "https://nid.naver.com/oauth2.0/token";

        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "authorization_code");
        params.add("client_id", oAuthProperties.getNaver().getClientId());
        params.add("client_secret", oAuthProperties.getNaver().getClientSecret());
        params.add("code", authCode);
        params.add("redirect_uri", redirectUri);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        ResponseEntity<NaverTokenResponse> response = restTemplate.postForEntity(
            tokenUrl, new HttpEntity<>(params, headers), NaverTokenResponse.class
        );

        if (response.getBody() == null || response.getBody().getAccessToken() == null) {
            throw new AuthException("INVALID_OAUTH_CODE", "네이버 토큰 발급에 실패했습니다.");
        }
        return response.getBody().getAccessToken();
    }

    private NaverUserInfo getNaverUserInfo(String accessToken) {
        String userInfoUrl = "https://openapi.naver.com/v1/nid/me";

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);

        ResponseEntity<NaverUserInfoWrapper> response = restTemplate.exchange(
            userInfoUrl, HttpMethod.GET, new HttpEntity<>(headers), NaverUserInfoWrapper.class
        );

        if (response.getBody() == null || response.getBody().getResponse() == null) {
            throw new AuthException("OAUTH_UPSTREAM_ERROR", "네이버 유저 정보 조회에 실패했습니다.");
        }
        return response.getBody().getResponse();
    }

    // ─── 내부 응답 매핑용 DTO ────────────────────────────────────────────

    @Getter
    private static class GoogleTokenResponse {
        @JsonProperty("access_token")
        private String accessToken;
    }

    @Getter
    private static class GoogleUserInfo {
        private String id;
        private String email;
        private String name;
    }

    @Getter
    private static class NaverTokenResponse {
        @JsonProperty("access_token")
        private String accessToken;
    }

    @Getter
    private static class NaverUserInfoWrapper {
        private NaverUserInfo response;
    }

    @Getter
    private static class NaverUserInfo {
        private String id;
        private String email;
        private String nickname;
    }
}
