// lib/models/chat_message.dart


class ChatMessage { // nullable

  ChatMessage({
    required this.id, // required berarti harus diisi
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isHelpful = false,
    this.feedbackNote,
    this.messageType,
    this.suggestions,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0, // Jika null, gunakan 0
      sessionId: json['session_id'] ?? '', // Jika null, gunakan string kosong
      role: json['role'] ?? 'bot', // Default 'bot'
      content: json['message'] ?? '', // Jika null, gunakan string kosong
      timestamp: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isHelpful: json['is_helpful'] ?? false,
      feedbackNote: json['feedback_note'],
      messageType: json['metadata'] != null && json['metadata'] is Map
          ? (json['metadata']['type'] ?? 'default')
          : 'default',
      suggestions:
          json['metadata'] != null && 
          json['metadata'] is Map &&
          json['metadata']['suggestions'] != null &&
          json['metadata']['suggestions'] is List
          ? (json['metadata']['suggestions'] as List)
              .map((s) => s.toString())
              .toList()
          : null,
    );
  }
  final int id; // non-nullable, tidak boleh null
  final String sessionId; // non-nullable
  final String role; // non-nullable ('user' or 'bot')
  final String content; // non-nullable
  final DateTime timestamp; // non-nullable
  final bool isHelpful; // non-nullable
  final String? feedbackNote; // nullable (boleh null)
  final String? messageType; // nullable
  final List<String>? suggestions;

  bool get isUser => role == 'user';
  bool get isBot => role == 'bot';

  // Getter dengan null safety
  String get safeContent => content.isNotEmpty ? content : '[Pesan kosong]';

  String get displayTime {
    try {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }
}

class ChatSession { // non-nullable

  ChatSession({
    required this.sessionId,
    required this.startedAt,
    required this.lastMessage,
    required this.messageCount,
    required this.userMessages,
    required this.botMessages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'] ?? '',
      startedAt: DateTime.parse(
        json['started_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessage: DateTime.parse(
        json['last_message'] ?? DateTime.now().toIso8601String(),
      ),
      messageCount: json['message_count'] ?? 0,
      userMessages: json['user_messages'] ?? 0,
      botMessages: json['bot_messages'] ?? 0,
    );
  }
  final String sessionId; // non-nullable
  final DateTime startedAt; // non-nullable
  final DateTime lastMessage; // non-nullable
  final int messageCount; // non-nullable
  final int userMessages; // non-nullable
  final int botMessages;

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(startedAt);

    if (diff.inDays == 0) {
      return 'Hari ini';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${startedAt.day}/${startedAt.month}/${startedAt.year}';
    }
  }

  String get duration {
    final diff = lastMessage.difference(startedAt);
    if (diff.inHours > 24) {
      return '${diff.inDays} hari';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit';
    } else {
      return '${diff.inSeconds} detik';
    }
  }
}
