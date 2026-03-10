import 'package:uuid/uuid.dart';

class Conversation {
  final String id;
  final String title;
  final String modelId;
  final String? systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  const Conversation({
    required this.id,
    required this.title,
    required this.modelId,
    this.systemPrompt,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  factory Conversation.create({
    String? title,
    String modelId = 'mock:default',
    String? systemPrompt,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: const Uuid().v4(),
      title: title ?? 'New Chat',
      modelId: modelId,
      systemPrompt: systemPrompt,
      createdAt: now,
      updatedAt: now,
    );
  }

  Conversation copyWith({
    String? id,
    String? title,
    String? modelId,
    String? systemPrompt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'modelId': modelId,
        'systemPrompt': systemPrompt,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'archived': archived ? 1 : 0,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String,
        modelId: json['modelId'] as String,
        systemPrompt: json['systemPrompt'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        archived: (json['archived'] as int?) == 1,
      );
}
