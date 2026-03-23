import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await ApiService.getAiHistory();
      final history = response.data as List;
      setState(() {
        _messages = history.map((m) => {
          'role': m['role'],
          'content': m['content'],
          'time': m['created_at'],
        }).toList();
      });
      _scrollToBottom();
    } catch (e) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'time': DateTime.now().toIso8601String(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await ApiService.chatWithAi(message);
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response.data['response'],
          'time': DateTime.now().toIso8601String(),
        });
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Kuch gadbad ho gayi! Dobara try karo 😅',
          'time': DateTime.now().toIso8601String(),
        });
        _isTyping = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('History clear karein?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ApiService.clearAiHistory();
              setState(() => _messages = []);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Color(0xFF0084FF), size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nex AI',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Powered by Llama 3.3',
                    style:
                        TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0084FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Color(0xFF0084FF), size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('Nex AI',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0084FF))),
                        const SizedBox(height: 8),
                        const Text('Kuch bhi pucho! Main hoon na 😊',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSuggestion('😂 Ek joke sunao'),
                            _buildSuggestion('🌤️ Aaj ka motivation'),
                            _buildSuggestion('💡 Koi tip do'),
                            _buildSuggestion('🤔 Kuch interesting batao'),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return _buildMessageBubble(msg, isUser);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text.substring(2).trim();
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0084FF).withValues(alpha: 0.3)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF0084FF))),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                color: Color(0xFF0084FF), size: 16),
            const SizedBox(width: 8),
            const Text('Nex AI likh raha hai...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0084FF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Color(0xFF0084FF), size: 12),
                    SizedBox(width: 4),
                    Text('Nex AI',
                        style: TextStyle(
                            color: Color(0xFF0084FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Text(
              msg['content'],
              style: TextStyle(
                fontSize: 15,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['time']),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Nex AI se kuch pucho...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0084FF),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
