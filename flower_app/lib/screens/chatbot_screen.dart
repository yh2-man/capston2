import 'package:flutter/material.dart';
import '../theme/season_theme.dart';

/// 공통 플레이스홀더 화면 (각 메뉴에서 재사용)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // 홈으로 돌아가기 버튼
          IconButton(
            icon: Icon(Icons.home_outlined, color: colors.primary),
            onPressed: () {
              // 메인 화면까지 전부 pop
              Navigator.popUntil(context, ModalRoute.withName('/main'));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: colors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('메인으로 돌아가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 각 화면 ──

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'AI 챗봇',
        icon: Icons.smart_toy_outlined,
        description: '꽃과 식물에 대해 무엇이든 물어보세요!\n(준비 중)',
      );
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: '커뮤니티',
        icon: Icons.people_alt_outlined,
        description: '산책 경로와 꽃 사진을 공유해요!\n(준비 중)',
      );
}

class FlowerBookScreen extends StatelessWidget {
  const FlowerBookScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: '꽃 도감',
        icon: Icons.menu_book_outlined,
        description: '지금까지 발견한 꽃들을 모아봐요!\n(준비 중)',
      );
}

class WalkScreen extends StatelessWidget {
  const WalkScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: '산책 기록',
        icon: Icons.directions_walk,
        description: '오늘의 산책 경로와 거리를 기록해요!\n(준비 중)',
      );
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: '저장됨',
        icon: Icons.bookmark_outline,
        description: '마음에 드는 꽃과 장소를 저장해요!\n(준비 중)',
      );
}
