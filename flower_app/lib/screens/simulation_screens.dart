import 'package:flutter/material.dart';
import '../models/chat_action.dart';

class MapSimulationWidget extends StatelessWidget {
  final ChatAction action;
  const MapSimulationWidget({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final params = action.params ?? {};
    final species = params['species'] as String?;
    final lat = params['lat'];
    final lng = params['lng'];
    final radius = params['radius'];

    return Container(
      color: const Color(0xFFF0F7F4),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SimBanner(icon: '🗺️', title: '챗봇이 지도를 조작했습니다.', color: const Color(0xFF6A9C89)),
          const SizedBox(height: 16),
          const _SectionTitle('수신된 파라미터'),
          const SizedBox(height: 8),
          _ParamCard(params: {
            if (species != null) '꽃 종류': species,
            if (lat != null) '위도': lat.toString(),
            if (lng != null) '경도': lng.toString(),
            if (radius != null) '반경': '${radius}m',
          }),
          const SizedBox(height: 16),
          _MapPlaceholder(species: species),
        ],
      ),
    );
  }
}

class CommunitySimulationWidget extends StatelessWidget {
  final ChatAction action;
  const CommunitySimulationWidget({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final params = action.params ?? {};
    final species = params['species'] as String?;

    return Container(
      color: const Color(0xFFFDF6F0),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SimBanner(icon: '👥', title: '챗봇이 커뮤니티 화면을 로드했습니다.', color: const Color(0xFFE07B54)),
          const SizedBox(height: 16),
          const _SectionTitle('수신된 파라미터'),
          const SizedBox(height: 8),
          _ParamCard(params: {
            if (species != null) '꽃 종류': species,
            if (params.isEmpty) '파라미터': '없음 (전체 보기)',
          }),
          const SizedBox(height: 16),
          _PostPlaceholder(species: species),
        ],
      ),
    );
  }
}

class _SimBanner extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  const _SimBanner({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF555555)));
  }
}

class _ParamCard extends StatelessWidget {
  final Map<String, String> params;
  const _ParamCard({required this.params});

  @override
  Widget build(BuildContext context) {
    if (params.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: const Text('없음', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: params.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Text(e.key, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
            const Spacer(),
            Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D2D2D))),
          ]),
        )).toList(),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String? species;
  const _MapPlaceholder({this.species});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFD8EDD5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A9C89).withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(species != null ? '$species 명소 지도' : '꽃 명소 지도',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A7C62))),
          ],
        ),
      ),
    );
  }
}

class _PostPlaceholder extends StatelessWidget {
  final String? species;
  const _PostPlaceholder({this.species});

  @override
  Widget build(BuildContext context) {
    final posts = [
      ('꽃사랑', species != null ? '$species 만개했어요! 🌸' : '오늘 꽃 구경 다녀왔어요 🌺', 24),
      ('자연인', species != null ? '$species 사진 공유해요' : '봄꽃이 너무 예뻐요', 18),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: posts.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE07B54).withOpacity(0.2),
              child: Text(p.$1[0], style: const TextStyle(color: Color(0xFFE07B54), fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF555555))),
                  const SizedBox(height: 2),
                  Text(p.$2, style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D2D))),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
