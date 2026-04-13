// [기능 ID: AUTH-01~06] [명세 근거: PRD §4.0]
package com.flower.backend.auth;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    // 일반(LOCAL) 로그인 전용. 소셜 로그인 유저는 null
    @Column
    private String password;

    @Column(nullable = false, length = 10)
    private String nickname;

    // 로그인 방식 구별 (LOCAL, GOOGLE, KAKAO, NAVER)
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Provider provider;

    // 소셜 로그인 전용. 각 소셜 서비스가 부여한 고유 ID
    @Column
    private String providerId;

    // FCM 푸시 알림용 기기 토큰
    @Column
    private String fcmToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    // ─── 일반(LOCAL) 회원가입용 정적 팩토리 메서드 ───────────────────────
    public static User createLocalUser(String email, String encodedPassword, String nickname) {
        User user = new User();
        user.email = email;
        user.password = encodedPassword;
        user.nickname = nickname;
        user.provider = Provider.LOCAL;
        user.role = Role.USER;
        return user;
    }

    // ─── 소셜(OAUTH) 회원가입용 정적 팩토리 메서드 ──────────────────────
    public static User createOAuthUser(String email, String nickname, Provider provider, String providerId) {
        User user = new User();
        user.email = email;
        user.password = null; // 소셜 유저는 비밀번호 없음
        user.nickname = nickname;
        user.provider = provider;
        user.providerId = providerId;
        user.role = Role.USER;
        return user;
    }

    public void updateNickname(String nickname) {
        this.nickname = nickname;
    }

    public void updateFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    // ─── 로그인 방식 구별용 Enum ──────────────────────────────────────────
    public enum Provider {
        LOCAL,   // 우리 서버에 이메일+비밀번호 저장
        GOOGLE,
        KAKAO,
        NAVER
    }

    public enum Role {
        USER,
        ADMIN
    }
}
