import '../models/chat_response.dart';
import '../models/message.dart';
import '../models/provider_model.dart';

class ChatParams {
  final double temperature;
  final int? maxTokens;
  final String? systemPrompt;

  const ChatParams({
    this.temperature = 0.7,
    this.maxTokens,
    this.systemPrompt,
  });
}

class ProviderHealth {
  final ProviderStatus status;
  final String? errorMessage;
  final DateTime checkedAt;

  ProviderHealth({
    required this.status,
    this.errorMessage,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();
}

abstract class LlmProvider {
  String get providerId;
  String get displayName;
  ProviderType get providerType;

  bool get requiresApiKey;
  bool get requiresNetwork;
  bool get supportsStreaming;

  Future<List<AiModel>> listModels();
  Future<AiModel?> getModelInfo(String modelId);

  Stream<ChatResponse> sendMessage({
    required String modelId,
    required List<Message> messages,
    required ChatParams params,
  });

  Future<ProviderHealth> checkHealth();
  ProviderStatus get currentStatus;

  Future<void> initialize();
  Future<void> dispose();
}
