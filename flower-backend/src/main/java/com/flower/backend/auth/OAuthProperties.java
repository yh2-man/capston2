// [기능 ID: AUTH-02,04] [명세 근거: PRD §4.0 / application-auth.yml]
package com.flower.backend.auth;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * application-auth.yml의 oauth.* 설정값을 자바 객체로 바인딩.
 * 카카오는 현재 미사용(주석 처리).
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "oauth")
public class OAuthProperties {

    private Google google = new Google();
    private Naver naver = new Naver();

    @Getter
    @Setter
    public static class Google {
        private String clientId;
        private String clientSecret;
    }

    @Getter
    @Setter
    public static class Naver {
        private String clientId;
        private String clientSecret;
    }
}
