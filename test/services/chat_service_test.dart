import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/models/chat_response.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/provider_model.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/llm_provider.dart';
import 'package:private_chat_hub/services/provider_registry.dart';

class _CapturingProvider implements LlmProvider {
  ChatParams? lastParams;
  List<Message>? lastMessages;

  @override
  ProviderStatus get currentStatus => ProviderStatus.ready;

  @override
  String get displayName => 'Capturing Provider';

  @override
  String get providerId => 'capture';

  @override
  ProviderType get providerType => ProviderType.local;

  @override
  bool get requiresApiKey => false;

  @override
  bool get requiresNetwork => false;

  @override
  bool get supportsStreaming => true;

  @override
  Future<ProviderHealth> checkHealth() async {
    return ProviderHealth(status: ProviderStatus.ready);
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<AiModel?> getModelInfo(String modelId) async {
    return const AiModel(
      qualifiedId: 'capture:model',
      providerId: 'capture',
      displayName: 'Capture Model',
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<List<AiModel>> listModels() async {
    return const [
      AiModel(
        qualifiedId: 'capture:model',
        providerId: 'capture',
        displayName: 'Capture Model',
      ),
    ];
  }

  @override
  Stream<ChatResponse> sendMessage({
    required String modelId,
    required List<Message> messages,
    required ChatParams params,
  }) async* {
    lastParams = params;
    lastMessages = messages;
    yield const ChatResponseContent('ok');
    yield const ChatResponseUsage(inputTokens: 3, outputTokens: 5);
  }
}

void main() {
  group('ChatService', () {
    test('passes conversation system prompt and skips pending messages',
        () async {
      final registry = ProviderRegistry();
      final provider = _CapturingProvider();
      registry.register(provider);
      final service = ChatService(registry);

      final history = [
        Message(
          id: 'user-1',
          conversationId: 'conversation-1',
          role: MessageRole.user,
          content: 'Hello',
          timestamp: DateTime.parse('2025-01-01T10:00:00Z'),
        ),
        Message(
          id: 'assistant-pending',
          conversationId: 'conversation-1',
          role: MessageRole.assistant,
          content: '',
          status: MessageStatus.sending,
          timestamp: DateTime.parse('2025-01-01T10:00:01Z'),
        ),
      ];

      final chunks = <String>[];
      int? inputTokens;
      int? outputTokens;
      final response = await service.sendMessage(
        conversationId: 'conversation-1',
        modelId: 'capture:model',
        history: history,
        userText: 'Hello',
        systemPrompt: 'You are concise.',
        onChunk: chunks.add,
        onUsage: (input, output) {
          inputTokens = input;
          outputTokens = output;
        },
      );

      expect(response, 'ok');
      expect(chunks, ['ok']);
      expect(inputTokens, 3);
      expect(outputTokens, 5);
      expect(provider.lastParams?.systemPrompt, 'You are concise.');
      expect(provider.lastMessages, hasLength(1));
      expect(provider.lastMessages!.single.content, 'Hello');
      expect(provider.lastMessages!.single.status, MessageStatus.sent);
    });
  });
}
