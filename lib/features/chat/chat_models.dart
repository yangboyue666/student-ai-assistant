import 'dart:convert';
import '../../core/llm/llm_service.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ChatSession.fromMap(Map<String, dynamic> m) {
    return ChatSession(
      id: m['id'] as String,
      title: m['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }

  ChatSession copyWith({String? title}) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class StoredChatMessage {
  final String id;
  final String sessionId;
  final String role; // user / assistant / tool
  final String content;
  final List<LlmToolCall>? toolCalls;
  final String? toolResult;
  final DateTime createdAt;

  StoredChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolResult,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'tool_calls': toolCalls == null || toolCalls!.isEmpty
          ? null
          : jsonEncode(toolCalls!.map((t) => t.toMap()).toList()),
      'tool_result': toolResult,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory StoredChatMessage.fromMap(Map<String, dynamic> m) {
    List<LlmToolCall>? calls;
    final raw = m['tool_calls'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          calls = decoded.map((e) {
            final map = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
            return LlmToolCall(
              id: map['id']?.toString() ?? '',
              name: map['name']?.toString() ?? '',
              arguments: map['arguments'] is String
                  ? map['arguments'] as String
                  : jsonEncode(map['arguments'] ?? {}),
            );
          }).toList();
        }
      } catch (_) {}
    }
    return StoredChatMessage(
      id: m['id'] as String,
      sessionId: m['session_id'] as String,
      role: m['role'] as String,
      content: m['content'] as String,
      toolCalls: calls,
      toolResult: m['tool_result'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  LlmMessage toLlmMessage() {
    return LlmMessage(
      role: role,
      content: content,
      toolCalls: toolCalls,
      toolResult: toolResult,
    );
  }
}
