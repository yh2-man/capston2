import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class CommunityPost {
  final int id;
  final String user;
  final String avatar;
  final String content;
  final String? flowerSpecies;
  final String? imageUrl;
  final int likeCount;
  bool liked;
  final String time;
  final String? location;

  CommunityPost({
    required this.id,
    required this.user,
    required this.avatar,
    required this.content,
    this.flowerSpecies,
    this.imageUrl,
    required this.likeCount,
    this.liked = false,
    required this.time,
    this.location,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as int,
      user: json['nickname'] as String? ?? '익명',
      avatar: '🌸',
      content: json['content'] as String,
      flowerSpecies: json['flowerSpecies'] as String?,
      imageUrl: json['imageUrl'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
      liked: json['liked'] as bool? ?? false,
      time: json['createdAt'] as String? ?? '',
      location: json['address'] as String?,
    );
  }
}

class CommunityApiService {
  static Future<List<CommunityPost>> getPosts(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/community/posts'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        return data.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockPosts();
  }

  static Future<void> likePost(String accessToken, int postId) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/community/posts/$postId/like'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static List<CommunityPost> _mockPosts() => [
    CommunityPost(id: 1, user: '꽃사랑봄', avatar: '🌸', content: '오늘 여의도에서 만개한 벚꽃을 발견했어요! 정말 예쁘더라구요 🌸',
      flowerSpecies: '벚꽃', likeCount: 42, time: '30분 전', location: '여의도 한강공원'),
    CommunityPost(id: 2, user: '산책매니아', avatar: '🚶', content: '산책길에 노란 개나리가 활짝 폈네요. 봄이 왔다는 걸 실감합니다!',
      flowerSpecies: '개나리', likeCount: 28, liked: true, time: '1시간 전', location: '남산 둘레길'),
    CommunityPost(id: 3, user: '플라워헌터', avatar: '🔍', content: '관악산 등산로에서 진달래 군락지를 발견했습니다! 퀘스트 인증 완료 ✅',
      flowerSpecies: '진달래', likeCount: 56, time: '3시간 전', location: '관악산 등산로'),
    CommunityPost(id: 4, user: '정원사킴', avatar: '🌱', content: '동네 공원에 목련이 피기 시작했어요. 향기가 정말 좋습니다~',
      flowerSpecies: '목련', likeCount: 35, time: '5시간 전', location: '올림픽공원'),
    CommunityPost(id: 5, user: '자연탐험가', avatar: '🌿', content: '용산 식물원 튤립 축제 다녀왔습니다. 색깔별로 너무 예뻐요! 🌷',
      flowerSpecies: '튤립', likeCount: 89, liked: true, time: '어제', location: '용산 식물원'),
  ];
}
