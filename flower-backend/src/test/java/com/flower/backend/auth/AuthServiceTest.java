package com.flower.backend.auth;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.BDDMockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService 단위 테스트")
class AuthServiceTest {

    @InjectMocks
    private AuthService authService;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtProvider jwtProvider;

    // ─── 회원가입 ────────────────────────────────────────────────────────
    @Test
    @DisplayName("회원가입 성공 → 유저 저장 및 토큰 반환")
    void signup_success() {
        var request = new AuthDto.SignupRequest();
        setField(request, "email", "new@flower.com");
        setField(request, "password", "test1234");
        setField(request, "nickname", "꽃향기");

        given(userRepository.existsByEmail("new@flower.com")).willReturn(false);
        given(userRepository.existsByNickname("꽃향기")).willReturn(false);
        given(passwordEncoder.encode("test1234")).willReturn("encoded_pw");
        given(userRepository.save(any())).willAnswer(i -> i.getArgument(0));
        given(jwtProvider.generateAccessToken(any())).willReturn("access_token");
        given(jwtProvider.generateRefreshToken(any())).willReturn("refresh_token");
        given(jwtProvider.getAccessTokenValidSeconds()).willReturn(3600L);

        var response = authService.signup(request);

        assertThat(response.getAccessToken()).isEqualTo("access_token");
        assertThat(response.getRefreshToken()).isEqualTo("refresh_token");
    }

    @Test
    @DisplayName("이미 사용 중인 이메일로 회원가입 → EMAIL_ALREADY_EXISTS 예외")
    void signup_duplicateEmail_throwsException() {
        var request = new AuthDto.SignupRequest();
        setField(request, "email", "dup@flower.com");
        setField(request, "password", "test1234");
        setField(request, "nickname", "중복닉");

        given(userRepository.existsByEmail("dup@flower.com")).willReturn(true);

        assertThatThrownBy(() -> authService.signup(request))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "EMAIL_ALREADY_EXISTS");
    }

    // ─── 로그인 ──────────────────────────────────────────────────────────
    @Test
    @DisplayName("일반 로그인 성공 → 토큰 반환")
    void login_success() {
        var request = new AuthDto.LoginRequest();
        setField(request, "email", "test@flower.com");
        setField(request, "password", "test1234");

        User mockUser = User.createLocalUser("test@flower.com", "encoded_pw", "꽃향기");
        given(userRepository.findByEmail("test@flower.com")).willReturn(Optional.of(mockUser));
        given(passwordEncoder.matches("test1234", "encoded_pw")).willReturn(true);
        given(jwtProvider.generateAccessToken(any())).willReturn("access_token");
        given(jwtProvider.generateRefreshToken(any())).willReturn("refresh_token");
        given(jwtProvider.getAccessTokenValidSeconds()).willReturn(3600L);

        var response = authService.login(request);

        assertThat(response.getAccessToken()).isEqualTo("access_token");
    }

    @Test
    @DisplayName("잘못된 비밀번호로 로그인 → INVALID_CREDENTIALS 예외")
    void login_wrongPassword_throwsException() {
        var request = new AuthDto.LoginRequest();
        setField(request, "email", "test@flower.com");
        setField(request, "password", "wrongpw");

        User mockUser = User.createLocalUser("test@flower.com", "encoded_pw", "꽃향기");
        given(userRepository.findByEmail("test@flower.com")).willReturn(Optional.of(mockUser));
        given(passwordEncoder.matches("wrongpw", "encoded_pw")).willReturn(false);

        assertThatThrownBy(() -> authService.login(request))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "INVALID_CREDENTIALS");
    }

    @Test
    @DisplayName("존재하지 않는 이메일로 로그인 → INVALID_CREDENTIALS 예외")
    void login_notFound_throwsException() {
        var request = new AuthDto.LoginRequest();
        setField(request, "email", "ghost@flower.com");
        setField(request, "password", "test1234");

        given(userRepository.findByEmail("ghost@flower.com")).willReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "INVALID_CREDENTIALS");
    }

    @Test
    @DisplayName("소셜 유저가 일반 로그인 시도 → INVALID_CREDENTIALS 예외")
    void login_oauthUser_tryLocalLogin_throwsException() {
        var request = new AuthDto.LoginRequest();
        setField(request, "email", "kakao@flower.com");
        setField(request, "password", "test1234");

        // 소셜로 가입된 유저를 LOCAL 필터로 걸면 empty가 됨
        given(userRepository.findByEmail("kakao@flower.com")).willReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(request))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "INVALID_CREDENTIALS");
    }

    // ─── 토큰 갱신 ───────────────────────────────────────────────────────
    @Test
    @DisplayName("유효한 Refresh Token → 새 Access Token 반환")
    void refresh_success() {
        var request = new AuthDto.RefreshRequest();
        setField(request, "refreshToken", "valid_refresh_token");

        given(jwtProvider.validateToken("valid_refresh_token")).willReturn(true);
        given(jwtProvider.getUserId("valid_refresh_token")).willReturn(1L);
        given(jwtProvider.generateAccessToken(1L)).willReturn("new_access_token");
        given(jwtProvider.getAccessTokenValidSeconds()).willReturn(3600L);

        var response = authService.refresh(request);

        assertThat(response.getAccessToken()).isEqualTo("new_access_token");
    }

    @Test
    @DisplayName("만료된 Refresh Token → INVALID_REFRESH_TOKEN 예외")
    void refresh_expiredToken_throwsException() {
        var request = new AuthDto.RefreshRequest();
        setField(request, "refreshToken", "expired_token");

        given(jwtProvider.validateToken("expired_token")).willReturn(false);

        assertThatThrownBy(() -> authService.refresh(request))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "INVALID_REFRESH_TOKEN");
    }

    // ─── 로그아웃 ────────────────────────────────────────────────────────
    @Test
    @DisplayName("로그아웃 성공 → FCM 토큰 null 초기화 (푸시 알림 차단)")
    void logout_success_clearsFcmToken() {
        User mockUser = User.createLocalUser("test@flower.com", "encoded_pw", "꽃향기");
        mockUser.updateFcmToken("device-fcm-token-abc"); // 로그인 상태에서 FCM 토큰 있음

        given(userRepository.findById(1L)).willReturn(Optional.of(mockUser));
        given(userRepository.save(any())).willReturn(mockUser);

        authService.logout(1L);

        // FCM 토큰이 null로 초기화되었는지 검증
        assertThat(mockUser.getFcmToken()).isNull();
        verify(userRepository).save(mockUser); // DB에 저장 호출 확인
    }

    @Test
    @DisplayName("존재하지 않는 유저 로그아웃 → 에러 없이 무시됨")
    void logout_nonExistentUser_silentlyIgnored() {
        given(userRepository.findById(999L)).willReturn(Optional.empty());

        // 존재하지 않는 유저 로그아웃 시도해도 예외 없이 조용히 넘어가야 함
        assertThatCode(() -> authService.logout(999L))
            .doesNotThrowAnyException();
    }

    // ─── 기존 계정 이메일 충돌 ────────────────────────────────────────────
    @Test
    @DisplayName("일반 가입 이메일로 소셜 로그인 시도 → EMAIL_ALREADY_EXISTS 예외")
    void processOAuth_emailConflictWithLocalUser_throwsException() {
        // providerId로는 못 찾고(신규처럼 보임), 이메일은 이미 일반 회원이 쓰고 있는 상황
        given(userRepository.findByProviderAndProviderId(User.Provider.GOOGLE, "google-123"))
            .willReturn(Optional.empty()); // 소셜 계정으로는 없음
        given(userRepository.existsByEmail("local@flower.com"))
            .willReturn(true); // 근데 이 이메일로 일반 가입은 돼 있음

        assertThatThrownBy(() ->
            authService.processOAuth("local@flower.com", "꽃사랑", User.Provider.GOOGLE, "google-123"))
            .isInstanceOf(AuthException.class)
            .hasFieldOrPropertyWithValue("errorCode", "EMAIL_ALREADY_EXISTS");
    }

    @Test
    @DisplayName("기존 소셜 계정으로 재로그인 → 즉시 토큰 반환")
    void processOAuth_existingSocialUser_returnsLoginResponse() {
        User mockUser = User.createOAuthUser("flower@google.com", "꽃향기", User.Provider.GOOGLE, "google-456");
        given(userRepository.findByProviderAndProviderId(User.Provider.GOOGLE, "google-456"))
            .willReturn(Optional.of(mockUser));
        given(jwtProvider.generateAccessToken(any())).willReturn("access_token");
        given(jwtProvider.generateRefreshToken(any())).willReturn("refresh_token");
        given(jwtProvider.getAccessTokenValidSeconds()).willReturn(3600L);

        Object result = authService.processOAuth("flower@google.com", "꽃향기", User.Provider.GOOGLE, "google-456");

        assertThat(result).isInstanceOf(AuthDto.LoginResponse.class);
        AuthDto.LoginResponse response = (AuthDto.LoginResponse) result;
        assertThat(response.getAccessToken()).isEqualTo("access_token");
    }

    // ─── 테스트용 필드 주입 헬퍼 ─────────────────────────────────────────
    private void setField(Object target, String fieldName, Object value) {
        try {
            var field = target.getClass().getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(target, value);
        } catch (Exception e) {
            throw new RuntimeException("테스트 필드 설정 실패: " + fieldName, e);
        }
    }
}

