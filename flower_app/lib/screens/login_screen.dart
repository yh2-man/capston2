import 'package:flutter/material.dart';
import '../theme/season_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ── 앱 로고 영역 ──
              _buildLogo(colors),

              const SizedBox(height: 48),

              // ── 이메일 입력칸 ──
              _buildTextField(
                controller: _emailController,
                hint: '이메일',
                icon: Icons.email_outlined,
                colors: colors,
              ),

              const SizedBox(height: 16),

              // ── 비밀번호 입력칸 ──
              _buildPasswordField(colors),

              const SizedBox(height: 8),

              // ── 비밀번호 찾기 ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // TODO: 비밀번호 찾기
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 로그인 버튼 ──
              _buildLoginButton(colors, context),

              const SizedBox(height: 20),

              // ── 구분선 ──
              _buildDivider(colors),

              const SizedBox(height: 20),

              // ── 소셜 로그인 버튼들 ──
              _buildKakaoButton(),

              const SizedBox(height: 12),

              _buildGoogleButton(),

              const SizedBox(height: 32),

              // ── 회원가입 링크 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '아직 계정이 없으신가요?  ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {}, // TODO: 회원가입 화면으로
                    child: Text(
                      '회원가입',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
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
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_florist_rounded,
            size: 50,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'OurT',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${colors.name}의 꽃과 함께 산책해요',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ── 일반 텍스트 필드 ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required SeasonColors colors,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: colors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }

  // ── 비밀번호 필드 ──
  Widget _buildPasswordField(SeasonColors colors) {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: '비밀번호',
        prefixIcon: Icon(Icons.lock_outline, color: colors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }

  // ── 로그인 버튼 ──
  Widget _buildLoginButton(SeasonColors colors, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // TODO: 로그인 로직 연결
          // 지금은 바로 메인 화면으로 이동
          Navigator.pushReplacementNamed(context, '/main');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: const Text(
          '로그인',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── 구분선 ──
  Widget _buildDivider(SeasonColors colors) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('또는', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  // ── 카카오 버튼 ──
  Widget _buildKakaoButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {}, // TODO: 카카오 로그인
        icon: const Icon(Icons.chat_bubble, color: Color(0xFF3C1E1E)),
        label: const Text(
          '카카오로 계속하기',
          style: TextStyle(
            color: Color(0xFF3C1E1E),
            fontSize: 15,
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
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {}, // TODO: 구글 로그인
        icon: const Icon(Icons.g_mobiledata, size: 26, color: Color(0xFF4285F4)),
        label: const Text(
          'Google로 계속하기',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 15,
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
}
