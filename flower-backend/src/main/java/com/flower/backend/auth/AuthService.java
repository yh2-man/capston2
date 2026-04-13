// [기능 ID: AUTH-01~06] [명세 근거: PRD §4.0 / API Spec §2.1~2.6]
package com.flower.backend.auth;

import com.flower.backend.auth.AuthDto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;

    // ─── 일반(LOCAL) 회원가입 ────────────────────────────────────────────
    @Transactional
    public LoginResponse signup(SignupRequest request) {
        // 이메일/닉네임 중복 체크
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new AuthException("EMAIL_ALREADY_EXISTS", "이미 사용 중인 이메일입니다.");
        }
        if (userRepository.existsByNickname(request.getNickname())) {
            throw new AuthException("NICKNAME_ALREADY_EXISTS", "이미 사용 중인 닉네임입니다.");
        }

        // 비밀번호 암호화 후 유저 저장
        String encodedPassword = passwordEncoder.encode(request.getPassword());
        User user = User.createLocalUser(request.getEmail(), encodedPassword, request.getNickname());
        userRepository.save(user);

        return buildLoginResponse(user);
    }

    // ─── 일반(LOCAL) 로그인 ──────────────────────────────────────────────
    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .filter(u -> u.getProvider() == User.Provider.LOCAL) // 소셜 유저가 일반 로그인 시도 차단
                .orElseThrow(() -> new AuthException("INVALID_CREDENTIALS", "이메일 또는 비밀번호가 올바르지 않습니다."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new AuthException("INVALID_CREDENTIALS", "이메일 또는 비밀번호가 올바르지 않습니다.");
        }

        return buildLoginResponse(user);
    }

    // ─── 소셜(OAuth) 로그인/회원가입 ─────────────────────────────────────
    // 실제 소셜 API 호출은 각 Provider별 OAuthService 에서 처리 후 이 메서드로 유저 정보를 전달
    @Transactional
    public Object processOAuth(String email, String nickname, User.Provider provider, String providerId) {
        // 1순위: provider + providerId로 기존 소셜 유저 찾기
        return userRepository.findByProviderAndProviderId(provider, providerId)
                .map(existingUser -> (Object) buildLoginResponse(existingUser)) // 기존 소셜 유저 → 바로 로그인
                .orElseGet(() -> {
                    // 2순위: 같은 이메일로 이미 가입된 계정이 있는지 확인 (예: 일반 회원이 소셜 로그인 시도)
                    boolean emailAlreadyExists = userRepository.existsByEmail(email);
                    if (emailAlreadyExists) {
                        throw new AuthException("EMAIL_ALREADY_EXISTS",
                            "동일 이메일로 이미 가입된 계정이 있습니다. 기존 로그인 방식을 사용해 주세요.");
                    }
                    // 3순위: 완전 신규 유저 → 닉네임 설정 화면으로 안내
                    String tempToken = jwtProvider.generateTempToken(email, provider.name());
                    return OAuthNewUserResponse.builder()
                            .isNewUser(true)
                            .tempToken(tempToken)
                            .provider(provider.name())
                            .providerEmail(email)
                            .build();
                });
    }


    // ─── 소셜 신규 유저 닉네임 설정 후 최종 회원가입 ─────────────────────
    @Transactional
    public LoginResponse setNickname(NicknameRequest request) {
        if (!jwtProvider.validateToken(request.getTempToken())) {
            throw new AuthException("TEMP_TOKEN_EXPIRED", "임시 토큰이 만료되었습니다.");
        }
        if (userRepository.existsByNickname(request.getNickname())) {
            throw new AuthException("NICKNAME_ALREADY_EXISTS", "이미 사용 중인 닉네임입니다.");
        }

        String email = jwtProvider.getEmail(request.getTempToken());
        String providerStr = jwtProvider.getProvider(request.getTempToken());
        User.Provider provider = User.Provider.valueOf(providerStr);

        // 이미 같은 이메일로 가입된 소셜 유저가 있는지 최종 확인
        User user = userRepository.findByEmail(email)
                .orElseGet(() -> {
                    User newUser = User.createOAuthUser(email, request.getNickname(), provider, null);
                    return userRepository.save(newUser);
                });

        return buildLoginResponse(user);
    }

    // ─── Access Token 재발급 ─────────────────────────────────────────────
    public RefreshResponse refresh(RefreshRequest request) {
        if (!jwtProvider.validateToken(request.getRefreshToken())) {
            throw new AuthException("INVALID_REFRESH_TOKEN", "유효하지 않은 Refresh Token입니다.");
        }
        Long userId = jwtProvider.getUserId(request.getRefreshToken());
        String newAccessToken = jwtProvider.generateAccessToken(userId);

        return RefreshResponse.builder()
                .accessToken(newAccessToken)
                .expiresIn(jwtProvider.getAccessTokenValidSeconds())
                .build();
    }

    // ─── 로그아웃 ────────────────────────────────────────────────────────
    // 현재는 Stateless 방식: 클라이언트에서 토큰 삭제로 처리
    // 추후 필요 시 DB에 Refresh Token 블랙리스트 테이블 추가하여 서버 측 무효화 가능
    public void logout(Long userId) {
        // FCM 토큰도 함께 초기화 (로그아웃 시 알림 안 받도록)
        userRepository.findById(userId).ifPresent(user -> {
            user.updateFcmToken(null);
            userRepository.save(user);
        });
    }

    // ─── 공통: 로그인 응답 객체 생성 ──────────────────────────────────────
    private LoginResponse buildLoginResponse(User user) {
        return LoginResponse.builder()
                .accessToken(jwtProvider.generateAccessToken(user.getId()))
                .refreshToken(jwtProvider.generateRefreshToken(user.getId()))
                .expiresIn(jwtProvider.getAccessTokenValidSeconds())
                .user(UserInfo.builder()
                        .userId(user.getId())
                        .nickname(user.getNickname())
                        .build())
                .build();
    }
}
