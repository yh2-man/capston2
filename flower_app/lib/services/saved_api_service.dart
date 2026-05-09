import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class SavedPostItem {
  final int id;
  final String user;
  final String avatar;
  final String content;
  final String flowerSpecies;
  final int likeCount;
  final String time;

  const SavedPostItem({
    required this.id, required this.user, required this.avatar,
    required this.content, required this.flowerSpecies,
    required this.likeCount, required this.time,
  });

  factory SavedPostItem.fromJson(Map<String, dynamic> json) {
    return SavedPostItem(
      id: json['id'] as int,
      user: json['nickname'] as String? ?? '익명',
      avatar: '🌸',
      content: json['content'] as String,
      flowerSpecies: json['flowerSpecies'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      time: json['createdAt'] as String? ?? '',
    );
  }
}

class SavedSpotItem {
  final int id;
  final String name;
  final String flowerSpecies;
  final String emoji;
  final String location;
  final String bloomPeriod;

  const SavedSpotItem({
    required this.id, required this.name, required this.flowerSpecies,
    required this.emoji, required this.location, required this.bloomPeriod,
  });

  factory SavedSpotItem.fromJson(Map<String, dynamic> json) {
    return SavedSpotItem(
      id: json['id'] as int,
      name: json['name'] as String,
      flowerSpecies: json['flowerSpecies'] as String? ?? '',
      emoji: '🌸',
      location: json['address'] as String? ?? '',
      bloomPeriod: json['bloomPeriod'] as String? ?? '',
    );
  }
}

class SavedApiService {
  static Future<List<SavedPostItem>> getSavedPosts(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/saved/posts'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        return data.map((e) => SavedPostItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockSavedPosts();
  }

  static Future<List<SavedSpotItem>> getSavedSpots(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/saved/spots'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        return data.map((e) => SavedSpotItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockSavedSpots();
  }

  static Future<void> unsavePost(String accessToken, int postId) async {
    try {
      await http.delete(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/saved/posts/$postId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<void> unsaveSpot(String accessToken, int spotId) async {
    try {
      await http.delete(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/saved/spots/$spotId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static List<SavedPostItem> _mockSavedPosts() => [
    const SavedPostItem(id: 1, user: '꽃사랑봄', avatar: '🌸',
      content: '여의도 벚꽃이 만개했어요! 오늘 산책하면서 찍은 사진입니다 🌸',
      flowerSpecies: '벚꽃', likeCount: 42, time: '4월 1일'),
    const SavedPostItem(id: 2, user: '놀이공원매니아', avatar: '🌷',
      content: '에버랜드 튤립축제 다녀왔는데 정말 장관이었어요.',
      flowerSpecies: '튤립', likeCount: 55, time: '3월 25일'),
    const SavedPostItem(id: 3, user: '제주도민', avatar: '🔴',
      content: '제주 카멜리아힐 동백꽃 보고 왔어요. 겨울에 가면 동백이 한가득!',
      flowerSpecies: '동백', likeCount: 42, time: '1월 15일'),
  ];

  static List<SavedSpotItem> _mockSavedSpots() => [
    const SavedSpotItem(id: 1, name: '여의도 벚꽃길', flowerSpecies: '벚꽃', emoji: '🌸',
      location: '서울 영등포구 여의도동', bloomPeriod: '3월 말 ~ 4월 중순'),
    const SavedSpotItem(id: 2, name: '에버랜드 튤립축제', flowerSpecies: '튤립', emoji: '🌷',
      location: '경기 용인시 처인구', bloomPeriod: '3월 ~ 4월'),
    const SavedSpotItem(id: 3, name: '순천만 국가정원 장미', flowerSpecies: '장미', emoji: '🌹',
      location: '전남 순천시', bloomPeriod: '5월 ~ 6월'),
    const SavedSpotItem(id: 4, name: '올림픽공원 들꽃마루', flowerSpecies: '코스모스', emoji: '🌼',
      location: '서울 송파구', bloomPeriod: '9월 ~ 10월'),
  ];
}
