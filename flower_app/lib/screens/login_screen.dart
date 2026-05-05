import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../theme/season_theme.dart';
import '../services/auth_api_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // OAuth 인증 페이지로 리다이렉트
  void _loginWith(String provider, String authUrl) {
    // 어떤 소셜 서비스로 로그인 시도했는지 저장 (콜백에서 사용)
    html.window.localStorage['oauth_provider'] = provider;
    html.window.location.href = authUrl;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── 앱 로고 영역 ──
              _buildLogo(colors),

              const Spacer(flex: 2),

              // ── 카카오 로그인 버튼 ──
              _buildKakaoButton(context),

              const SizedBox(height: 12),

              // ── 구글 로그인 버튼 ──
              _buildGoogleButton(context),

              const SizedBox(height: 12),

              // ── 네이버 로그인 버튼 ──
              _buildNaverButton(context),

              const Spacer(flex: 2),

              // ── 하단 안내 문구 ──
              Text(
                '로그인 시 이용약관 및 개인정보 처리방침에 동의합니다.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 로고 위젯 ──
  Widget _buildLogo(SeasonColors colors) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_florist_rounded,
            size: 56,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'OurT',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: colors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${colors.name}의 꽃과 함께 산책해요',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ── 카카오 버튼 ──
  Widget _buildKakaoButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: application-auth.yml의 kakao client-id를 여기에 입력
          const clientId = 'YOUR_KAKAO_REST_API_KEY';
          _loginWith('kakao', AuthApiService.getKakaoAuthUrl(clientId));
        },
        icon: const Icon(Icons.chat_bubble, color: Color(0xFF3C1E1E)),
        label: const Text(
          '카카오로 시작하기',
          style: TextStyle(
            color: Color(0xFF3C1E1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ── 구글 버튼 ──
  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: Google Cloud Console의 client-id를 여기에 입력
          const clientId = 'YOUR_GOOGLE_CLIENT_ID';
          _loginWith('google', AuthApiService.getGoogleAuthUrl(clientId));
        },
        icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
        label: const Text(
          'Google로 시작하기',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  // ── 네이버 버튼 ──
  Widget _buildNaverButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Naver Developers의 client-id를 여기에 입력
          const clientId = 'YOUR_NAVER_CLIENT_ID';
          _loginWith('naver', AuthApiService.getNaverAuthUrl(clientId));
        },
        icon: const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        label: const Text(
          '네이버로 시작하기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03C75A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
