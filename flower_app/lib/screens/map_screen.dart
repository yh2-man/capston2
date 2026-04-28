import 'package:flutter/material.dart';
import '../theme/season_theme.dart';

/// 지도 화면 (배경 탭 시 진입)
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();
    return Scaffold(
      body: Stack(
        children: [
          // 전체 지도 배경
          Container(
            color: const Color(0xFFE8F4E8),
            child: CustomPaint(
              painter: _FullMapPainter(colors),
              size: MediaQuery.of(context).size,
            ),
          ),
          // 상단 뒤로가기 + 검색바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _backButton(context, colors),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search, color: colors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '장소, 꽃 검색',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 지도 중앙 마커 예시
          Center(
            child: Icon(Icons.local_florist, color: colors.primary, size: 40),
          ),
          // 하단 힌트
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '지도에서 꽃 위치를 확인하세요 🌸',
                  style: TextStyle(color: colors.primary, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _backButton(BuildContext context, SeasonColors colors) {
  return GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Icon(Icons.arrow_back_ios_new, color: colors.primary, size: 18),
    ),
  );
}

class _FullMapPainter extends CustomPainter {
  final SeasonColors colors;
  _FullMapPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 10;
    final block = Paint()
      ..color = colors.secondary.withOpacity(0.2);

    for (double y = 60; y < size.height; y += 120) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
    for (double x = 50; x < size.width; x += 110) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (double x = 55; x < size.width; x += 110) {
      for (double y = 65; y < size.height; y += 120) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 75, 75), const Radius.circular(6)),
          block,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
