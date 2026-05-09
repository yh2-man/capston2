import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class WalkRecord {
  final String day;
  final int stepCount;

  const WalkRecord({required this.day, required this.stepCount});

  factory WalkRecord.fromJson(Map<String, dynamic> json) {
    return WalkRecord(
      day: json['recordDate'] as String? ?? '',
      stepCount: json['stepCount'] as int? ?? 0,
    );
  }
}

class PointHistory {
  final String desc;
  final int amount;
  final String type;
  final String time;

  const PointHistory({required this.desc, required this.amount, required this.type, required this.time});
}

class WalkApiService {
  static Future<List<WalkRecord>> getWeeklyRecords(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/walk/records/weekly'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        return data.map((e) => WalkRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _mockWeekly();
  }

  static Future<int> getPointBalance(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/walk/points'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data']['balance'] as int? ?? 0;
      }
    } catch (_) {}
    return 320;
  }

  static Future<void> syncSteps(String accessToken, int steps) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.backendBaseUrl()}/api/v1/walk/sync'),
        headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'stepCount': steps}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static List<WalkRecord> _mockWeekly() => [
    const WalkRecord(day: '월', stepCount: 8234),
    const WalkRecord(day: '화', stepCount: 6128),
    const WalkRecord(day: '수', stepCount: 10502),
    const WalkRecord(day: '목', stepCount: 7891),
    const WalkRecord(day: '금', stepCount: 5422),
    const WalkRecord(day: '토', stepCount: 12300),
    const WalkRecord(day: '일', stepCount: 4283),
  ];

  static List<PointHistory> mockPointHistory() => [
    const PointHistory(desc: '걸음 포인트 적립', amount: 42, type: 'STEP', time: '오늘 09:30'),
    const PointHistory(desc: '벚꽃 퀘스트 완료', amount: 50, type: 'QUEST', time: '어제 14:20'),
    const PointHistory(desc: '커피 쿠폰 교환', amount: -100, type: 'SHOP', time: '3일 전'),
    const PointHistory(desc: '걸음 포인트 적립', amount: 103, type: 'STEP', time: '3일 전'),
    const PointHistory(desc: '장미 퀘스트 완료', amount: 75, type: 'QUEST', time: '5일 전'),
  ];
}
