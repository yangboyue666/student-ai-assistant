import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';
import '../../core/llm/llm_service.dart';
import 'chat_models.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();
  final _uuid = const Uuid();

  Future<ChatSession> createSession({String? title}) async {
    final db = await AppDatabase.instance.database;
    final id = _uuid.v4();
    final now = DateTime.now();
    final session = ChatSession(
      id: id,
      title: title ?? '新对话 ${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      createdAt: now,
      updatedAt: now,
    );
    await db.insert(Tables.chatSessions, session.toMap());
    return session;
  }

  Future<List<ChatSession>> allSessions() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.chatSessions,
      orderBy: 'updated_at DESC',
      limit: 50,
    );
    return rows.map(ChatSession.fromMap).toList();
  }

  Future<ChatSession?> getSession(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(Tables.chatSessions, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ChatSession.fromMap(rows.first);
  }

  Future<void> renameSession(String id, String title) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      Tables.chatSessions,
      {
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.chatSessions, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StoredChatMessage>> messagesForSession(String sessionId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.chatMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(StoredChatMessage.fromMap).toList();
  }

  Future<void> addMessage(StoredChatMessage msg) async {
    final db = await AppDatabase.instance.database;
    await db.insert(Tables.chatMessages, msg.toMap());
    await db.update(
      Tables.chatSessions,
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [msg.sessionId],
    );
  }

  Future<void> clearSession(String sessionId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.chatMessages, where: 'session_id = ?', whereArgs: [sessionId]);
  }

  /// 把会话消息转换为 LLM 输入格式
  Future<List<LlmMessage>> buildLlmMessages(String sessionId) async {
    final msgs = await messagesForSession(sessionId);
    return msgs.map((m) => m.toLlmMessage()).toList();
  }

  // 给 StoredChatMessage.toMap 提供正确序列化（覆盖默认实现）
  static String? encodeToolCalls(List<LlmToolCall>? calls) {
    if (calls == null || calls.isEmpty) return null;
    return jsonEncode(calls.map((c) => c.toMap()).toList());
  }

  static List<LlmToolCall>? decodeToolCalls(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .map((e) {
              final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
              return LlmToolCall(
                id: m['id']?.toString() ?? '',
                name: m['name']?.toString() ?? '',
                arguments: m['arguments'] is String
                    ? m['arguments'] as String
                    : jsonEncode(m['arguments'] ?? {}),
              );
            })
            .toList();
      }
    } catch (_) {}
    return null;
  }
}
