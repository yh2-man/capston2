// [기능 ID: AUTH-02,04] [테스트 대상: OAuthService]
package com.flower.backend.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

/**
 * OAuthService 단위 테스트
 * - MockRestServiceServer: 실제 HTTP 요청 없이 가짜 구글/네이버 서버 응답을 만들어 테스트
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("OAuthService 단위 테스트 (Google/Naver)")
class OAuthServiceTest {

    private OAuthService oAuthService;
    private MockRestServiceServer mockServer;

    @Mock
    private AuthService authService;

    @Mock
    private OAuthProperties oAuthProperties;

    @Mock
    private OAuthProperties.Google googleProps;

    @Mock
    private OAuthProperties.Naver naverProps;

    @BeforeEach
    void setUp() {
        // RestTemplate에 가짜 서버를 붙여서 실제 외부 HTTP 호출 차단
        RestTemplate restTemplate = new RestTemplate();
        mockServer = MockRestServiceServer.createServer(restTemplate);

        oAuthService = new OAuthService(oAuthProperties, authService, restTemplate);

        // OAuthProperties 설정값 바인딩
        given(oAuthProperties.getGoogle()).willReturn(googleProps);
        given(oAuthProperties.getNaver()).willReturn(naverProps);
        given(googleProps.getClientId()).willReturn("test-google-client-id");
        given(googleProps.getClientSecret()).willReturn("test-google-secret");
        given(naverProps.getClientId()).willReturn("test-naver-client-id");
        given(naverProps.getClientSecret()).willReturn("test-naver-secret");
    }

    // ─── 구글 OAuth 테스트 ────────────────────────────────────────────────

    @Test
    @DisplayName("구글 OAuth - 기존 회원이면 로그인 토큰 즉시 반환")
    void google_existingUser_returnsLoginResponse() {
        // 1. 구글 Access Token 발급 응답 (가짜 서버)
        mockServer.expect(requestTo("https://oauth2.googleapis.com/token"))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess(
                "{\"access_token\":\"google-access-token-abc\"}",
                MediaType.APPLICATION_JSON));

        // 2. 구글 유저 정보 조회 응답 (가짜 서버)
        mockServer.expect(requestTo("https://www.googleapis.com/oauth2/v2/userinfo"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withSuccess(
                "{\"id\":\"google-123\",\"email\":\"flower@gmail.com\",\"name\":\"꽃사랑\"}",
                MediaType.APPLICATION_JSON));

        // 3. 기존 회원 로그인 Mock
        var loginResponse = AuthDto.LoginResponse.builder()
            .accessToken("our-access-token")
            .refreshToken("our-refresh-token")
            .expiresIn(3600L)
            .user(AuthDto.UserInfo.builder().userId(1L).nickname("꽃사랑").build())
            .build();
        given(authService.processOAuth("flower@gmail.com", "꽃사랑", User.Provider.GOOGLE, "google-123"))
            .willReturn(loginResponse);

        // 실행 + 검증
        Object result = oAuthService.processGoogle("test-auth-code", "http://localhost/redirect");

        assertThat(result).isInstanceOf(AuthDto.LoginResponse.class);
        AuthDto.LoginResponse response = (AuthDto.LoginResponse) result;
        assertThat(response.getAccessToken()).isEqualTo("our-access-token");
        assertThat(response.getUser().getNickname()).isEqualTo("꽃사랑");
        mockServer.verify(); // 예상한 요청이 실제로 나갔는지 검증
    }

    @Test
    @DisplayName("구글 OAuth - 신규 회원이면 닉네임 설정 안내(tempToken 반환)")
    void google_newUser_returnsTempToken() {
        mockServer.expect(requestTo("https://oauth2.googleapis.com/token"))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess(
                "{\"access_token\":\"google-access-token-new\"}",
                MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://www.googleapis.com/oauth2/v2/userinfo"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withSuccess(
                "{\"id\":\"google-999\",\"email\":\"newbie@gmail.com\",\"name\":\"신입\"}",
                MediaType.APPLICATION_JSON));

        var newUserResponse = AuthDto.OAuthNewUserResponse.builder()
            .isNewUser(true)
            .tempToken("temp-token-xyz")
            .provider("GOOGLE")
            .providerEmail("newbie@gmail.com")
            .build();
        given(authService.processOAuth("newbie@gmail.com", "신입", User.Provider.GOOGLE, "google-999"))
            .willReturn(newUserResponse);

        Object result = oAuthService.processGoogle("test-auth-code", "http://localhost/redirect");

        assertThat(result).isInstanceOf(AuthDto.OAuthNewUserResponse.class);
        AuthDto.OAuthNewUserResponse response = (AuthDto.OAuthNewUserResponse) result;
        assertThat(response.isNewUser()).isTrue();
        assertThat(response.getTempToken()).isEqualTo("temp-token-xyz");
        assertThat(response.getProvider()).isEqualTo("GOOGLE");
        mockServer.verify();
    }

    @Test
    @DisplayName("구글 OAuth - 토큰 발급 실패 시 INVALID_OAUTH_CODE 예외")
    void google_invalidAuthCode_throwsException() {
        // 구글 서버가 access_token 없이 빈 응답 반환
        mockServer.expect(requestTo("https://oauth2.googleapis.com/token"))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() ->
            oAuthService.processGoogle("bad-code", "http://localhost/redirect"))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "INVALID_OAUTH_CODE");

        mockServer.verify();
    }

    // ─── 네이버 OAuth 테스트 ──────────────────────────────────────────────

    @Test
    @DisplayName("네이버 OAuth - 기존 회원이면 로그인 토큰 즉시 반환")
    void naver_existingUser_returnsLoginResponse() {
        mockServer.expect(requestTo("https://nid.naver.com/oauth2.0/token"))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess(
                "{\"access_token\":\"naver-access-token-abc\"}",
                MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://openapi.naver.com/v1/nid/me"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withSuccess(
                "{\"response\":{\"id\":\"naver-456\",\"email\":\"flower@naver.com\",\"nickname\":\"꽃향기\"}}",
                MediaType.APPLICATION_JSON));

        var loginResponse = AuthDto.LoginResponse.builder()
            .accessToken("our-access-token")
            .refreshToken("our-refresh-token")
            .expiresIn(3600L)
            .user(AuthDto.UserInfo.builder().userId(2L).nickname("꽃향기").build())
            .build();
        given(authService.processOAuth("flower@naver.com", "꽃향기", User.Provider.NAVER, "naver-456"))
            .willReturn(loginResponse);

        Object result = oAuthService.processNaver("test-auth-code", "http://localhost/redirect");

        assertThat(result).isInstanceOf(AuthDto.LoginResponse.class);
        AuthDto.LoginResponse response = (AuthDto.LoginResponse) result;
        assertThat(response.getAccessToken()).isEqualTo("our-access-token");
        assertThat(response.getUser().getNickname()).isEqualTo("꽃향기");
        mockServer.verify();
    }

    @Test
    @DisplayName("네이버 OAuth - 신규 회원이면 닉네임 설정 안내(tempToken 반환)")
    void naver_newUser_returnsTempToken() {
        mockServer.expect(requestTo("https://nid.naver.com/oauth2.0/token"))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess(
                "{\"access_token\":\"naver-access-token-new\"}",
                MediaType.APPLICATION_JSON));

        mockServer.expect(requestTo("https://openapi.naver.com/v1/nid/me"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withSuccess(
                "{\"response\":{\"id\":\"naver-777\",\"email\":\"new@naver.com\",\"nickname\":\"새싹\"}}",
                MediaType.APPLICATION_JSON));

        var newUserResponse = AuthDto.OAuthNewUserResponse.builder()
            .isNewUser(true)
            .tempToken("temp-naver-token")
            .provider("NAVER")
            .providerEmail("new@naver.com")
            .build();
        given(authService.processOAuth("new@naver.com", "새싹", User.Provider.NAVER, "naver-777"))
            .willReturn(newUserResponse);

        Object result = oAuthService.processNaver("test-auth-code", "http://localhost/redirect");

        assertThat(result).isInstanceOf(AuthDto.OAuthNewUserResponse.class);
        AuthDto.OAuthNewUserResponse response = (AuthDto.OAuthNewUserResponse) result;
        assertThat(response.isNewUser()).isTrue();
        assertThat(response.getProvider()).isEqualTo("NAVER");
        mockServer.verify();
    }

    @Test
    @DisplayName("네이버 OAuth - 토큰 발급 실패 시 INVALID_OAUTH_CODE 예외")
    void naver_invalidAuthCode_throwsException() {
        mockServer.expect(requestTo("https://nid.naver.com/oauth2.0/token"))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));

        assertThatThrownBy(() ->
            oAuthService.processNaver("bad-code", "http://localhost/redirect"))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "INVALID_OAUTH_CODE");

        mockServer.verify();
    }
}
