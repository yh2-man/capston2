import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import 'map_screen.dart';
import 'chatbot_screen.dart';
import 'community_screen.dart';
import 'flower_book_screen.dart';
import 'walk_screen.dart';
import 'saved_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: 지도 배경 (탭하면 지도 화면으로) ──
          _buildMapBackground(context, colors, size),

          // ── Layer 2: 배경 탭 힌트 ──
          _buildMapHint(colors),

          // ── Layer 3: 상단 바 ──
          _buildTopBar(context, colors),

          // ── Layer 4: 하단 플로팅 버튼 그룹 ──
          _buildFloatingMenu(context, colors),
        ],
      ),
    );
  }

  // ── 지도 배경 ──
  Widget _buildMapBackground(BuildContext context, SeasonColors colors, Size size) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          );
        },
        child: Container(
          color: const Color(0xFFE8F4E8),
          child: CustomPaint(
            painter: _MapGridPainter(colors),
          ),
        ),
      ),
    );
  }

  // ── 배경 탭 힌트 (상단 중앙) ──
  Widget _buildMapHint(SeasonColors colors) {
    return Positioned(
      top: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 15, color: colors.primary),
              const SizedBox(width: 5),
              Text(
                '화면을 터치하면 지도가 열려요',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 상단 바 ──
  Widget _buildTopBar(BuildContext context, SeasonColors colors) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.primary.withOpacity(0.15),
                child: Icon(Icons.person, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '산책중인 사용자',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${SeasonTheme.getColors().name} 탐험가',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.search, color: colors.primary),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.menu, color: colors.primary),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 하단 플로팅 버튼 그룹 (항상 표시) ──
  Widget _buildFloatingMenu(BuildContext context, SeasonColors colors) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SizedBox(
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 좌상단: 커뮤니티
              _positioned(
                dx: -95, dy: -80,
                child: _subBtn(
                  context,
                  icon: Icons.people_alt_outlined,
                  label: '커뮤니티',
                  colors: colors,
                  onTap: () => _goTo(context, const CommunityScreen()),
                ),
              ),
              // 우상단: 꽃 도감
              _positioned(
                dx: 95, dy: -80,
                child: _subBtn(
                  context,
                  icon: Icons.menu_book_outlined,
                  label: '꽃 도감',
                  colors: colors,
                  onTap: () => _goTo(context, const FlowerBookScreen()),
                ),
              ),
              // 좌하단: 산책 기록
              _positioned(
                dx: -95, dy: 80,
                child: _subBtn(
                  context,
                  icon: Icons.directions_walk,
                  label: '산책 기록',
                  colors: colors,
                  onTap: () => _goTo(context, const WalkScreen()),
                ),
              ),
              // 우하단: 저장됨
              _positioned(
                dx: 95, dy: 80,
                child: _subBtn(
                  context,
                  icon: Icons.bookmark_outline,
                  label: '저장됨',
                  colors: colors,
                  onTap: () => _goTo(context, const SavedScreen()),
                ),
              ),
              // 중앙: AI 챗봇
              _buildChatbotButton(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  // 위치 헬퍼
  Widget _positioned({required double dx, required double dy, required Widget child}) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: child,
    );
  }

  // 서브 버튼 위젯
  Widget _subBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required SeasonColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 중앙 챗봇 버튼
  Widget _buildChatbotButton(BuildContext context, SeasonColors colors) {
    return GestureDetector(
      onTap: () => _goTo(context, const ChatbotScreen()),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.45),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 32),
      ),
    );
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

// ── 지도 모의 배경 painter ──
class _MapGridPainter extends CustomPainter {
  final SeasonColors colors;
  _MapGridPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final subRoadPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (double y = 80; y < size.height; y += 140) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 60; x < size.width; x += 130) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 80 + 70; y < size.height; y += 140) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subRoadPaint);
    }

    final blockPaint = Paint()
      ..color = colors.secondary.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    for (double x = 70; x < size.width; x += 130) {
      for (double y = 90; y < size.height; y += 140) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 90, 90),
            const Radius.circular(6),
          ),
          blockPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}
