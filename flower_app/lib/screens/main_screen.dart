import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import 'kakao_map_screen.dart';
import 'chatbot_screen.dart';
import 'community_screen.dart';
import 'flower_book_screen.dart';
import 'walk_screen.dart';
import 'saved_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<KakaoMapScreenState> _mapKey = GlobalKey<KakaoMapScreenState>();
  final TextEditingController _mapSearchController = TextEditingController();
  bool _isMapMode = false;

  @override
  void dispose() {
    _mapSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: KakaoMapScreen(key: _mapKey, isEmbedded: true),
          ),
          if (!_isMapMode)
            Positioned(
              top: 106,
              left: 10,
              right: 10,
              bottom: 240,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _showMapMode(),
              ),
            ),
          if (!_isMapMode) _buildTopBar(context, colors),
          if (_isMapMode) _buildMapModeTopBar(colors),
          if (_isMapMode) _buildMapModeControls(colors),
          if (!_isMapMode) _buildFloatingMenu(context, colors),
        ],
      ),
    );
  }

  void _showMapMode() {
    if (_isMapMode) return;
    setState(() => _isMapMode = true);
  }

  void _showMainMode() {
    if (!_isMapMode) return;
    setState(() => _isMapMode = false);
  }

  Future<void> _submitMapSearch(String value) async {
    await _mapKey.currentState?.setSearchQuery(value.trim());
  }

  Future<void> _zoomMapIn() async => _mapKey.currentState?.zoomIn();
  Future<void> _zoomMapOut() async => _mapKey.currentState?.zoomOut();
  Future<void> _moveToCurrentLocation() async => _mapKey.currentState?.moveToCurrentLocation();

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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))],
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
                  const Text('산책중인 사용자', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${SeasonTheme.getColors().name} 탐험가', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              const Spacer(),
              IconButton(icon: Icon(Icons.search, color: colors.primary), onPressed: _showMapMode),
              IconButton(icon: Icon(Icons.menu, color: colors.primary), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapModeTopBar(SeasonColors colors) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: colors.primary, size: 18),
                tooltip: '메인 모드',
                onPressed: _showMainMode,
              ),
              Expanded(
                child: TextField(
                  controller: _mapSearchController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: '꽃 이름, 종류, 주소',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  onSubmitted: _submitMapSearch,
                ),
              ),
              IconButton(
                icon: Icon(Icons.search, color: colors.primary),
                tooltip: '검색',
                onPressed: () => _submitMapSearch(_mapSearchController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapModeControls(SeasonColors colors) {
    return Positioned(
      top: 100,
      right: 16,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mapControlButton(colors: colors, icon: Icons.add, tooltip: '확대', onTap: _zoomMapIn),
            const SizedBox(height: 8),
            _mapControlButton(colors: colors, icon: Icons.remove, tooltip: '축소', onTap: _zoomMapOut),
            const SizedBox(height: 8),
            _mapControlButton(colors: colors, icon: Icons.my_location, tooltip: '현재 위치', onTap: _moveToCurrentLocation),
          ],
        ),
      ),
    );
  }

  Widget _mapControlButton({
    required SeasonColors colors,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
          ),
          child: Icon(icon, color: colors.primary, size: 22),
        ),
      ),
    );
  }

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
              _positioned(dx: -95, dy: -80,
                child: _subBtn(context, icon: Icons.people_alt_outlined, label: '커뮤니티', colors: colors,
                  onTap: () => _goTo(context, const CommunityScreen()))),
              _positioned(dx: 95, dy: -80,
                child: _subBtn(context, icon: Icons.menu_book_outlined, label: '꽃 도감', colors: colors,
                  onTap: () => _goTo(context, const FlowerBookScreen()))),
              _positioned(dx: -95, dy: 80,
                child: _subBtn(context, icon: Icons.directions_walk, label: '산책 기록', colors: colors,
                  onTap: () => _goTo(context, const WalkScreen()))),
              _positioned(dx: 95, dy: 80,
                child: _subBtn(context, icon: Icons.bookmark_outline, label: '저장됨', colors: colors,
                  onTap: () => _goTo(context, const SavedScreen()))),
              _buildChatbotButton(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _positioned({required double dx, required double dy, required Widget child}) =>
      Transform.translate(offset: Offset(dx, dy), child: child);

  Widget _subBtn(BuildContext context, {
    required IconData icon, required String label,
    required SeasonColors colors, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white,
              boxShadow: [BoxShadow(color: colors.primary.withOpacity(0.25), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotButton(BuildContext context, SeasonColors colors) {
    return GestureDetector(
      onTap: () => _goTo(context, const ChatbotScreen()),
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: colors.primary,
          boxShadow: [BoxShadow(color: colors.primary.withOpacity(0.45), blurRadius: 20, spreadRadius: 4)],
        ),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 32),
      ),
    );
  }

  void _goTo(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
