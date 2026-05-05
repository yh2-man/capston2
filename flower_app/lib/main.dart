import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/auth_api_service.dart';
import 'theme/season_theme.dart';

void main() {
  // 앱 시작 시 URL에 auth code가 있는지 확인 (OAuth 콜백)
  final uri = Uri.parse(html.window.location.href);
  final authCode = uri.queryParameters['code'];
  final isOAuthCallback = authCode != null;

  runApp(OurTApp(isOAuthCallback: isOAuthCallback, authCode: authCode));
}

class OurTApp extends StatelessWidget {
  final bool isOAuthCallback;
  final String? authCode;

  const OurTApp({
    super.key,
    this.isOAuthCallback = false,
    this.authCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();

    return MaterialApp(
      title: 'OurT',
      debugShowCheckedModeBanner: false,
      theme: colors.toThemeData(),
      // OAuth 콜백이면 처리 화면, 아니면 로그인 화면
      home: isOAuthCallback
          ? OAuthProcessingScreen(authCode: authCode!)
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

/// OAuth 인증 코드를 백엔드로 전송하고 결과에 따라 라우팅하는 화면
class OAuthProcessingScreen extends StatefulWidget {
  final String authCode;
  const OAuthProcessingScreen({super.key, required this.authCode});

  @override
  State<OAuthProcessingScreen> createState() => _OAuthProcessingScreenState();
}

class _OAuthProcessingScreenState extends State<OAuthProcessingScreen> {
  String _status = '로그인 처리 중...';

  @override
  void initState() {
    super.initState();
    _processOAuth();
  }

  Future<void> _processOAuth() async {
    try {
      // localStorage에서 어떤 소셜 서비스인지 확인
      final provider = html.window.localStorage['oauth_provider'] ?? 'kakao';

      setState(() => _status = '서버와 통신 중...');

      // 백엔드에 auth_code 전송
      final result = await AuthApiService.sendAuthCode(
        provider: provider,
        authCode: widget.authCode,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        if (data['isNewUser'] == true) {
          // 신규 유저 → tempToken 저장 후 프로필 설정으로
          html.window.localStorage['tempToken'] = data['tempToken'] ?? '';
          // URL 정리 (code 파라미터 제거)
          html.window.history.replaceState(null, '', '/');
          Navigator.pushReplacementNamed(context, '/profile-setup');
        } else {
          // 기존 유저 → 토큰 저장 후 메인으로
          html.window.localStorage['accessToken'] = data['accessToken'] ?? '';
          html.window.localStorage['refreshToken'] = data['refreshToken'] ?? '';
          html.window.history.replaceState(null, '', '/');
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        // Spring 기본 에러 형식: {"status":400, "error":"Bad Request", "message":"..."}
        // 커스텀 에러 형식: {"success":false, "error":{"code":"...", "message":"..."}}
        String errorMsg;
        final errorField = result['error'];
        if (errorField is Map) {
          errorMsg = errorField['message']?.toString() ?? '알 수 없는 오류';
        } else {
          errorMsg = result['message']?.toString() ?? errorField?.toString() ?? '알 수 없는 오류';
        }
        setState(() => _status = '로그인 실패: $errorMsg');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '오류 발생: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 24),
            Text(
              _status,
              style: TextStyle(fontSize: 16, color: colors.primary),
            ),
            if (_status.startsWith('로그인 실패') || _status.startsWith('오류'))
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: () {
                    html.window.history.replaceState(null, '', '/');
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('돌아가기'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
