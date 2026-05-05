import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// 백엔드 API와 OAuth 흐름을 관리하는 서비스.
class AuthApiService {
  // 로컬 테스트 시 백엔드 주소
  static const String baseUrl = 'http://localhost:8080/api/v1/auth';

  // Flutter 웹 앱의 OAuth 콜백 URL (포트 5000 고정)
  static const String webCallbackUrl = 'http://localhost:5000/oauth-callback';

  // ─── 각 소셜 서비스 인증 URL 생성 ──────────────────────────

  static String getGoogleAuthUrl(String clientId) {
    return 'https://accounts.google.com/o/oauth2/v2/auth'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(webCallbackUrl)}'
        '&response_type=code'
        '&scope=openid%20profile';
  }

  static String getKakaoAuthUrl(String clientId) {
    return 'https://kauth.kakao.com/oauth/authorize'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(webCallbackUrl)}'
        '&response_type=code';
  }

  static String getNaverAuthUrl(String clientId) {
    return 'https://nid.naver.com/oauth2.0/authorize'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(webCallbackUrl)}'
        '&response_type=code'
        '&state=naver_login';
  }

  // ─── auth_code를 백엔드에 전송 ─────────────────────────────

  static Future<Map<String, dynamic>> sendAuthCode({
    required String provider, // google, kakao, naver
    required String authCode,
  }) async {
    final url = '$baseUrl/oauth/$provider';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authCode': authCode,
        'redirectUri': webCallbackUrl,
      }),
    );

    return jsonDecode(response.body);
  }

  // ─── 프로필 설정 (신규 유저) ────────────────────────────────

  static Future<Map<String, dynamic>> setupProfile({
    required String tempToken,
    required String nickname,
    String? profileImageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile-setup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tempToken': tempToken,
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
      }),
    );

    return jsonDecode(response.body);
  }
}
