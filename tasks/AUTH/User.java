// [기능 ID: AUTH-01~03] [명세 근거: PRD §4.0]
// ⚠️ 이 파일은 작업 참고용 사본입니다.
// 실제 동작하는 코드는 flower-backend/src/main/java/com/flower/backend/auth/User.java
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

    @Column(nullable = false, length = 10)
    private String nickname;

    // Oracle Cloud Storage에 저장된 프로필 이미지 URL
    @Column(length = 1024)
    private String profileImageUrl;

    // 로그인 방식 구별 (카카오 단일)
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Provider provider;

    // 카카오가 부여한 고유 ID (provider + providerId로 유저 식별)
    @Column(nullable = false)
    private String providerId;

    // FCM 푸시 알림용 기기 토큰
    @Column
    private String fcmToken;

    @Column
    private Double lastLatitude;

    @Column
    private Double lastLongitude;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    // ─── 카카오 소셜 회원가입용 정적 팩토리 메서드 ─────────────────────
    public static User createOAuthUser(String nickname, String profileImageUrl, Provider provider, String providerId) {
        User user = new User();
        user.nickname = nickname;
        user.profileImageUrl = profileImageUrl;
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

    public void updateLocation(Double latitude, Double longitude) {
        this.lastLatitude = latitude;
        this.lastLongitude = longitude;
    }

    // ─── 로그인 방식 구별용 Enum (카카오 단일) ─────────────────────────
    public enum Provider {
        KAKAO
    }

    public enum Role {
        USER,
        ADMIN
    }
}
