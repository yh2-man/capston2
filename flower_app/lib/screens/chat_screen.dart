import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_action.dart';
import '../services/chatbot_service.dart';
import '../widgets/message_bubble.dart';
import 'simulation_screens.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();

  late String _sessionId;
  bool _isLoading = false;
  ChatAction? _currentAction;

  @override
  void initState() {
    super.initState();
    _initSession();
    _addBotMessage('안녕하세요! 꽃에 대해 궁금한 점이나 가고 싶은 곳을 말씀해 주세요. 🌸');
  }

  void _initSession() {
    _sessionId = const Uuid().v4();
  }

  Future<void> _resetSession() async {
    try {
      await _chatbotService.clearSession(_sessionId);
    } catch (e) {
      debugPrint('세션 초기화 실패: $e');
    }
    setState(() {
      _messages.clear();
      _currentAction = null;
      _initSession();
      _addBotMessage('대화가 초기화되었습니다. 새로 질문해 주세요! 🌸');
    });
  }

  void _addBotMessage(String text, {ChatAction? action}) {
    setState(() {
      _messages.insert(0, ChatMessage.bot(text, action: action));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.insert(0, ChatMessage.user(text));
      _messages.insert(0, ChatMessage.loading());
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatbotService.sendMessage(
        message: text,
        sessionId: _sessionId,
        lat: 37.5665,
        lng: 126.9780,
      );

      setState(() {
        _messages.removeAt(0);
        _addBotMessage(response.reply, action: response.action);
        _isLoading = false;
        if (response.action != null && response.action!.type == 'NAVIGATE') {
          _currentAction = response.action;
        }
      });
    } catch (e) {
      setState(() {
        _messages.removeAt(0);
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _closeSimulation() => setState(() => _currentAction = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text('FLOWER 챗봇', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF6A9C89),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '대화 초기화',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('대화 초기화'),
                  content: const Text('현재 대화 내용을 모두 지우고 세션을 초기화하시겠습니까?'),
                  actions: [
                    TextButton(
                      child: const Text('취소', style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('초기화', style: TextStyle(color: Color(0xFFE07B54))),
                      onPressed: () {
                        Navigator.pop(context);
                        _resetSession();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentAction != null)
            Expanded(flex: 4, child: _buildSimulationView(_currentAction!)),
          if (_currentAction != null)
            Container(height: 2, color: Colors.grey.withOpacity(0.2)),
          Expanded(
            flex: _currentAction != null ? 6 : 10,
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  onActionTap: message.action != null && message.action!.type == 'NAVIGATE'
                      ? () => setState(() => _currentAction = message.action)
                      : null,
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSimulationView(ChatAction action) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: action.target == 'MAP' ? const Color(0xFF6A9C89) : const Color(0xFFE07B54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  action.target == 'MAP' ? '지도 시뮬레이터' : '커뮤니티 시뮬레이터',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _closeSimulation,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Expanded(
            child: action.target == 'MAP'
                ? MapSimulationWidget(action: action)
                : CommunitySimulationWidget(action: action),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF0F3F1), borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _textController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: TextStyle(color: Color(0xFFA0AAB2)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: Color(0xFF6A9C89), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
