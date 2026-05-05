import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../services/auth_api_service.dart';

/// OAuth 인증 후 리다이렉트되는 콜백 화면.
/// URL에서 auth_code를 추출하여 백엔드에 전송하고 결과에 따라 라우팅합니다.
class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  String _status = '로그인 처리 중...';

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // URL에서 auth code와 provider 추출
      final uri = Uri.parse(html.window.location.href);
      final authCode = uri.queryParameters['code'];
      final state = uri.queryParameters['state']; // 네이버는 state 파라미터 사용

      if (authCode == null) {
        setState(() => _status = '인증 코드를 받지 못했습니다.');
        return;
      }

      // provider 판별 (이전 화면에서 localStorage에 저장한 값 사용)
      final provider = html.window.localStorage['oauth_provider'] ?? 'google';

      setState(() => _status = '서버와 통신 중...');

      // 백엔드에 auth_code 전송
      final result = await AuthApiService.sendAuthCode(
        provider: provider,
        authCode: authCode,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        if (data['isNewUser'] == true) {
          // 신규 유저 → 프로필 설정으로 이동 (tempToken 전달)
          html.window.localStorage['tempToken'] = data['tempToken'];
          Navigator.pushReplacementNamed(context, '/profile-setup');
        } else {
          // 기존 유저 → 토큰 저장 후 메인으로
          html.window.localStorage['accessToken'] = data['accessToken'];
          html.window.localStorage['refreshToken'] = data['refreshToken'];
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        final errorMsg = result['error']?['message'] ?? '알 수 없는 오류';
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(_status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
