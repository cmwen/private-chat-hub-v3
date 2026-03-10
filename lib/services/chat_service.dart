import 'dart:async';

import '../models/chat_response.dart';
import '../models/message.dart';
import '../models/provider_model.dart';
import 'llm_provider.dart';
import 'provider_registry.dart';

class ChatServiceException implements Exception {
  final String message;
  const ChatServiceException(this.message);

  @override
  String toString() => 'ChatServiceException: $message';
}

class ChatService {
  final ProviderRegistry _registry;

  ChatService(this._registry);

  /// Sends a message and streams back response chunks.
  /// [onChunk] is called for each text chunk.
  /// [onUsage] is called with final token usage.
  /// Returns the complete response text.
  Future<String> sendMessage({
    required String conversationId,
    required String modelId,
    required List<Message> history,
    required String userText,
    required void Function(String chunk) onChunk,
    double temperature = 0.7,
    void Function(int inputTokens, int outputTokens)? onUsage,
  }) async {
    final provider = _registry.resolveProvider(modelId);
    if (provider == null) {
      throw ChatServiceException('No provider found for model: $modelId');
    }

    if (provider.currentStatus != ProviderStatus.ready) {
      throw ChatServiceException(
        'Provider ${provider.displayName} is not ready '
        '(status: ${provider.currentStatus.name})',
      );
    }

    final rawId = _registry.rawModelId(modelId);
    final params = ChatParams(temperature: temperature);

    final buffer = StringBuffer();

    await for (final response in provider.sendMessage(
      modelId: rawId,
      messages: history,
      params: params,
    )) {
      switch (response) {
        case ChatResponseContent(:final text):
          buffer.write(text);
          onChunk(text);
        case ChatResponseUsage(
            :final inputTokens,
            :final outputTokens,
          ):
          onUsage?.call(inputTokens, outputTokens);
        case ChatResponseError(:final message):
          throw ChatServiceException(message);
      }
    }

    return buffer.toString();
  }
}
