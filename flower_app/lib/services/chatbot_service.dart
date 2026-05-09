import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_config.dart';
import '../models/chat_action.dart';

class ChatbotResponse {
  final String reply;
  final ChatAction? action;

  const ChatbotResponse({required this.reply, this.action});
}

class ChatbotService {
  static String get _baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ApiConfig.backendBaseUrl(androidEmulator: false);
    }
    return ApiConfig.backendBaseUrl();
  }

  final Dio _client;

  ChatbotService({Dio? client})
      : _client = client ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ));

  Future<ChatbotResponse> sendMessage({
    required String message,
    required String sessionId,
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{'message': message, 'session_id': sessionId};
    if (lat != null && lng != null) {
      body['context'] = {'lat': lat, 'lng': lng};
    }

    try {
      final response = await _client.post<Map<String, dynamic>>('/chatbot/message', data: body);
      final json = response.data ?? <String, dynamic>{};
      final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final reply = data['reply'] as String? ?? '';
      final actionJson = data['action'] as Map<String, dynamic>?;
      final action = actionJson != null ? ChatAction.fromJson(actionJson) : null;
      return ChatbotResponse(reply: reply, action: action);
    } on DioException catch (error) {
      throw Exception(_messageFromDioError(error));
    }
  }

  Future<void> clearSession(String sessionId) async {
    await _client.delete<void>('/chatbot/session/$sessionId');
  }

  String _messageFromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorJson = data['error'];
      if (errorJson is Map<String, dynamic>) return errorJson['message'] as String? ?? '알 수 없는 오류가 발생했습니다.';
      if (errorJson is String && errorJson.isNotEmpty) return errorJson;
    }
    return error.message ?? '알 수 없는 오류가 발생했습니다.';
  }
}
