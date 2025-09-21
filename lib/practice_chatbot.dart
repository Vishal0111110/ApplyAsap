import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:share_plus/share_plus.dart';

class PracticeChatbot extends StatefulWidget {
  final List<dynamic> questions;
  final String category;
  final String career;
  final String lang;

  const PracticeChatbot({
    Key? key,
    required this.questions,
    required this.category,
    required this.career,
    required this.lang,
  }) : super(key: key);

  @override
  _PracticeChatbotState createState() => _PracticeChatbotState();
}

class _PracticeChatbotState extends State<PracticeChatbot> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _exportWAController = TextEditingController();
  final TextEditingController _exportEmailController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _chatHistory = [];
  bool _isLoading = false;
  bool _showHistory = false;
  String _searchQuery = '';
  String _currentSessionId = '';

  @override
  void initState() {
    super.initState();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _addInitialMessage();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _saveCurrentChat();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _exportWAController.dispose();
    _exportEmailController.dispose();
    super.dispose();
  }

  String getChatContent() {
    final StringBuffer buffer = StringBuffer();
    for (var message in _messages) {
      final sender = message.isUser ? "You" : "${widget.category} Assistant";
      buffer.writeln("$sender: ${message.content}");
    }
    return buffer.toString();
  }

  Future<void> _loadChatHistory() async {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final userId =
        isAuthenticated ? FirebaseAuth.instance.currentUser!.uid : 'anonymous';

    debugPrint('🔍 Practice Chat - User ID: $userId');
    debugPrint('🔍 Practice Chat - Is Authenticated: $isAuthenticated');

    final dbRef = FirebaseDatabase.instance
        .ref()
        .child('practice_chats')
        .child(userId)
        .child(widget.career.replaceAll(' ', '_').replaceAll('/', '_'));

    debugPrint('🔍 Practice Chat - Database Path: ${dbRef.path}');

    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final sessions = data.entries.map((entry) {
          final sessionData = entry.value as Map;
          final messages = (sessionData['messages'] as List).map((msg) {
            return ChatMessage(
              content: msg['content'],
              isUser: msg['isUser'],
            );
          }).toList();

          return ChatSession(
            id: entry.key,
            title: sessionData['title'] ?? 'Practice Chat Session',
            timestamp:
                DateTime.fromMillisecondsSinceEpoch(sessionData['timestamp']),
            messages: messages,
          );
        }).toList();

        sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _chatHistory.clear();
          _chatHistory.addAll(sessions);
        });
        debugPrint(
            '✅ Practice Chat - Successfully loaded ${sessions.length} sessions');
      } else {
        debugPrint('ℹ️ Practice Chat - No existing chat history found');
      }
    } catch (e) {
      debugPrint('❌ Error loading practice chat history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load chat history. Please try again.')),
      );
    }
  }

  Future<void> _saveCurrentChat() async {
    if (_messages.length <= 1) return;

    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final userId =
        isAuthenticated ? FirebaseAuth.instance.currentUser!.uid : 'anonymous';

    debugPrint('💾 Practice Chat - Saving chat for User ID: $userId');
    debugPrint('💾 Practice Chat - Is Authenticated: $isAuthenticated');

    final dbRef = FirebaseDatabase.instance
        .ref()
        .child('practice_chats')
        .child(userId)
        .child(widget.career.replaceAll(' ', '_').replaceAll('/', '_'))
        .child(_currentSessionId);

    debugPrint('💾 Practice Chat - Save Path: ${dbRef.path}');

    final firstUserMessage = _messages.firstWhere(
      (msg) => msg.isUser,
      orElse: () => _messages.first,
    );

    final title = firstUserMessage.content.length > 50
        ? '${firstUserMessage.content.substring(0, 50)}...'
        : firstUserMessage.content;

    final messagesData = _messages
        .map((msg) => {
              'content': msg.content,
              'isUser': msg.isUser,
            })
        .toList();

    try {
      await dbRef.set({
        'title': title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'messages': messagesData,
      });
      debugPrint('✅ Practice Chat - Successfully saved chat session');
    } catch (e) {
      debugPrint('❌ Error saving practice chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save chat. Please try again.')),
      );
    }
  }

  Future<void> _deleteChatSession(String sessionId) async {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final userId =
        isAuthenticated ? FirebaseAuth.instance.currentUser!.uid : 'anonymous';

    debugPrint('🗑️ Practice Chat - Deleting session for User ID: $userId');
    debugPrint('🗑️ Practice Chat - Session ID: $sessionId');

    final dbRef = FirebaseDatabase.instance
        .ref()
        .child('practice_chats')
        .child(userId)
        .child(widget.career.replaceAll(' ', '_').replaceAll('/', '_'))
        .child(sessionId);

    debugPrint('🗑️ Practice Chat - Delete Path: ${dbRef.path}');

    try {
      await dbRef.remove();
      setState(() {
        _chatHistory.removeWhere((session) => session.id == sessionId);
      });
      debugPrint('✅ Practice Chat - Successfully deleted session');
    } catch (e) {
      debugPrint('❌ Error deleting practice chat session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to delete chat session. Please try again.')),
      );
    }
  }

  void _startNewChat() {
    if (_messages.length > 1) {
      _saveCurrentChat();
    }

    setState(() {
      _messages.clear();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _showHistory = false;
    });

    _addInitialMessage();
    _loadChatHistory();
  }

  void _loadChatSession(ChatSession session) {
    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _currentSessionId = session.id;
      _showHistory = false;
    });
  }

  List<ChatSession> get _filteredHistory {
    if (_searchQuery.isEmpty) {
      return _chatHistory;
    }
    return _chatHistory.where((session) {
      return session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          session.messages.any((msg) =>
              msg.content.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  String _getRandomTypingMessage() {
    final messages = [
      'Analyzing practice questions...',
      'Searching through question explanations...',
      'Generating detailed answer...',
      'Thinking about the solution...',
      'Processing your question...',
      'Looking up question details...',
      'Preparing comprehensive explanation...',
    ];
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
  }

  void _addInitialMessage() {
    String categoryName = widget.category;
    if (widget.category == "DSA" || widget.category == "Dev") {
      categoryName = widget.category;
    } else if (widget.category == "English") {
      categoryName = "English";
    } else {
      categoryName = "Technical";
    }

    setState(() {
      _messages.add(ChatMessage(
        content:
            "Hi! I'm here to help you understand the $categoryName practice questions for ${widget.career}. Ask me anything about these questions, their solutions, or concepts you don't understand!",
        isUser: false,
      ));
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: message, isUser: true));
      _isLoading = true;
    });

    _messageController.clear();

    try {
      String response = await _getGeminiResponse(message);
      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            content:
                "Sorry, I couldn't process your question. Please try again.",
            isUser: false));
        _isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    final apiKey = await rootBundle.loadString('assets/gemini.key');
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?alt=json&key=$apiKey";

    String questionsText = widget.questions
        .map((q) {
          if (q is Map) {
            return "Question: ${q['questionText'] ?? q['question'] ?? 'N/A'}\nOptions: ${q['options']?.join(', ') ?? 'N/A'}\nCorrect Answer: ${q['correctOptionIndex'] != null ? (q['options']?[q['correctOptionIndex']] ?? 'N/A') : 'N/A'}";
          } else if (q.questionText != null) {
            return "Question: ${q.questionText}\nOptions: ${q.options?.join(', ') ?? 'N/A'}\nCorrect Answer: ${q.correctOptionIndex != null ? (q.options?[q.correctOptionIndex] ?? 'N/A') : 'N/A'}";
          }
          return "Question data not available";
        })
        .take(20)
        .join('\n\n');

    String systemPrompt = """
You are a helpful assistant that explains practice questions for ${widget.career} in the ${widget.category} category.

Based on the following practice questions:

${questionsText}

Answer the user's question about these practice questions. Be informative, detailed, and educational.
If the question is about a specific question, explain the concept, solution, and why the answer is correct.
If the question is about understanding a concept, provide clear explanations with examples.
If the question is about solving similar problems, give step-by-step guidance.
Keep responses educational and encouraging for learning.
""";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userMessage}
            ],
          },
        ],
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          },
        ],
        'generationConfig': {
          'candidateCount': 1,
          'temperature': 0.7,
          'topP': 0.8,
        },
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String text =
          jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      throw Exception('Failed to get response from Gemini');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          '${widget.category} Assistant',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShareChatScreen(
                    chatContent: getChatContent(),
                    chatTitle: '${widget.category} Practice Chat',
                    career: widget.career,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
          ),
        ],
      ),
      body: _showHistory ? _buildHistoryPanel() : _buildChatView(),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _messages.length) {
                return _messages[index];
              } else {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF424242)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5BC0EB).withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5BC0EB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.category + ' Assistant',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: SpinKitThreeBounce(
                                    color: const Color(0xFF5BC0EB),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getRandomTypingMessage(),
                                    style: const TextStyle(
                                      color: Color(0xFFB0B0B0),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            border: Border(top: BorderSide(color: const Color(0xFF424242))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask about ${widget.category} questions...',
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    filled: true,
                    fillColor: const Color(0xFF323232),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5BC0EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _sendMessage(_messageController.text),
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            border: Border(bottom: BorderSide(color: const Color(0xFF424242))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search practice chats...',
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    filled: true,
                    fillColor: const Color(0xFF323232),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFFB0B0B0)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _startNewChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BC0EB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'New Chat',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredHistory.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No practice chat history'
                        : 'No results found',
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredHistory.length,
                  itemBuilder: (context, index) {
                    final session = _filteredHistory[index];
                    return Dismissible(
                      key: Key(session.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF1F1F1F),
                              title: const Text(
                                'Delete Practice Chat',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Are you sure you want to delete this practice chat session?',
                                style: TextStyle(color: Color(0xFFB0B0B0)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Color(0xFF5BC0EB)),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _deleteChatSession(session.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Practice chat session deleted'),
                            backgroundColor: Colors.red,
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                // Note: Undo functionality would require storing the deleted session
                                // For now, just showing the snackbar without undo
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: const Color(0xFF1F1F1F),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: const Color(0xFF424242)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            session.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${session.timestamp.day}/${session.timestamp.month}/${session.timestamp.year} ${session.timestamp.hour}:${session.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                          ),
                          onTap: () => _loadChatSession(session),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteDialog(String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          title: const Text(
            'Delete Practice Chat',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this practice chat session?',
            style: TextStyle(color: Color(0xFFB0B0B0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF5BC0EB)),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteChatSession(sessionId);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String content;
  final bool isUser;

  const ChatMessage({
    Key? key,
    required this.content,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF5BC0EB) : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF424242)),
              ),
              child: MarkdownWidget(
                data: content,
                shrinkWrap: true,
                config: MarkdownConfig.darkConfig,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime timestamp;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
  });
}

class ShareChatScreen extends StatelessWidget {
  final String chatContent;
  final String chatTitle;
  final String career;

  const ShareChatScreen({
    Key? key,
    required this.chatContent,
    required this.chatTitle,
    required this.career,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'Share Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Preview Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF424242)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.chat,
                      color: Color(0xFF5BC0EB),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        chatTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Career: $career',
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF323232),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF424242)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      chatContent,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Share Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await Share.share(
                    'Check out this interesting chat about $career!\n\n$chatContent',
                    subject: chatTitle,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to share chat'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Share Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BC0EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Share your practice insights with friends and colleagues!',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
