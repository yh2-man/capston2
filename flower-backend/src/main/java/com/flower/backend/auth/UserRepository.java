// [기능 ID: AUTH-01~06] [명세 근거: PRD §4.0]
package com.flower.backend.auth;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByProviderAndProviderId(User.Provider provider, String providerId);

    boolean existsByNickname(String nickname);

    @Query(nativeQuery = true, value = """
        SELECT * FROM users
        WHERE fcm_token IS NOT NULL
          AND last_latitude IS NOT NULL
          AND last_longitude IS NOT NULL
          AND id <> :excludeUserId
          AND (6371000 * acos(LEAST(1.0,
                cos(radians(:lat)) * cos(radians(last_latitude)) *
                cos(radians(last_longitude) - radians(:lng)) +
                sin(radians(:lat)) * sin(radians(last_latitude))
              ))) <= :radiusM
        """)
    List<User> findNearbyUsersWithFcmToken(
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("radiusM") double radiusM,
            @Param("excludeUserId") Long excludeUserId);
}
