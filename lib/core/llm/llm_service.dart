import 'dart:async';
import 'dart:convert';

/// LLM 服务接口（端侧 AI 抽象）
abstract class LlmService {
  /// 是否已就绪（模型加载完成）
  Future<bool> isReady();

  /// 模型简短描述
  String describe();

  /// 单轮非流式：返回完整回复
  Future<String> complete(
    List<LlmMessage> messages, {
    List<LlmTool> tools = const [],
  });

  /// 流式输出：返回逐 token 流
  Stream<String> stream(
    List<LlmMessage> messages, {
    List<LlmTool> tools = const [],
  });
}

class LlmMessage {
  const LlmMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolResult,
    this.name,
  });

  /// system / user / assistant / tool
  final String role;
  final String content;
  final List<LlmToolCall>? toolCalls;
  final String? toolResult;
  final String? name;

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        if (toolCalls != null)
          'tool_calls': toolCalls!.map((t) => t.toMap()).toList(),
        if (toolResult != null) 'tool_result': toolResult,
        if (name != null) 'name': name,
      };

  factory LlmMessage.user(String text) =>
      LlmMessage(role: 'user', content: text);
  factory LlmMessage.system(String text) =>
      LlmMessage(role: 'system', content: text);
  factory LlmMessage.assistant(String text) =>
      LlmMessage(role: 'assistant', content: text);
}

class LlmTool {
  const LlmTool({
    required this.name,
    required this.description,
    required this.parameters,
    this.required = const [],
  });

  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final List<String> required;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'parameters': parameters,
        'required': required,
      };
}

class LlmToolCall {
  const LlmToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final String arguments;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'arguments': arguments,
      };

  Map<String, dynamic>? parseArguments() {
    if (arguments.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(arguments);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}
