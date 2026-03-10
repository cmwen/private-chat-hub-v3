import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system, tool }

enum MessageStatus { draft, queued, sending, sent, failed }

class TokenUsage {
  final int inputTokens;
  final int outputTokens;

  const TokenUsage({required this.inputTokens, required this.outputTokens});

  int get total => inputTokens + outputTokens;

  Map<String, dynamic> toJson() => {
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
      };

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
        inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
        outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      );
}

class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final MessageStatus status;
  final TokenUsage? tokenUsage;
  final double? costUsd;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.status = MessageStatus.sent,
    this.tokenUsage,
    this.costUsd,
    required this.timestamp,
  });

  factory Message.create({
    required String conversationId,
    required MessageRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
  }) {
    return Message(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: role,
      content: content,
      status: status,
      timestamp: DateTime.now(),
    );
  }

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    MessageStatus? status,
    TokenUsage? tokenUsage,
    double? costUsd,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      tokenUsage: tokenUsage ?? this.tokenUsage,
      costUsd: costUsd ?? this.costUsd,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'status': status.name,
        'tokenUsage': tokenUsage?.toJson(),
        'costUsd': costUsd,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        status: MessageStatus.values.byName(
          (json['status'] as String?) ?? 'sent',
        ),
        tokenUsage: json['tokenUsage'] != null
            ? TokenUsage.fromJson(json['tokenUsage'] as Map<String, dynamic>)
            : null,
        costUsd: (json['costUsd'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
