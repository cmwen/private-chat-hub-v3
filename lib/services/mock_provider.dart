import 'dart:async';
import '../models/chat_response.dart';
import '../models/message.dart';
import '../models/provider_model.dart';
import 'llm_provider.dart';

const List<AiModel> _mockModels = [
  AiModel(
    qualifiedId: 'mock:default',
    providerId: 'mock',
    displayName: 'Mock Assistant',
    contextWindow: 4096,
    capabilities: ModelCapabilities(
      streaming: true,
      systemPrompt: true,
    ),
  ),
  AiModel(
    qualifiedId: 'mock:fast',
    providerId: 'mock',
    displayName: 'Mock Fast',
    contextWindow: 2048,
    capabilities: ModelCapabilities(streaming: true),
  ),
];

const _mockResponses = [
  "Hello! I'm the Mock Assistant. I'm here to help you test Private Chat Hub.",
  "That's an interesting question! As a mock provider, I can simulate responses for testing purposes.",
  "I understand. Let me think about that... As a placeholder AI, I provide canned responses to help you build and test the app.",
  "Great point! The app is designed with a provider-agnostic architecture, so swapping me out for a real LLM like Ollama or a cloud provider is straightforward.",
  "Thanks for chatting! Remember, you can configure a real provider in Settings.",
];

int _responseIndex = 0;

class MockProvider implements LlmProvider {
  ProviderStatus _status = ProviderStatus.ready;

  @override
  String get providerId => 'mock';

  @override
  String get displayName => 'Mock Provider';

  @override
  ProviderType get providerType => ProviderType.local;

  @override
  bool get requiresApiKey => false;

  @override
  bool get requiresNetwork => false;

  @override
  bool get supportsStreaming => true;

  @override
  ProviderStatus get currentStatus => _status;

  @override
  Future<void> initialize() async {
    _status = ProviderStatus.ready;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<List<AiModel>> listModels() async => _mockModels;

  @override
  Future<AiModel?> getModelInfo(String modelId) async {
    try {
      return _mockModels.firstWhere((m) => m.qualifiedId == modelId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ChatResponse> sendMessage({
    required String modelId,
    required List<Message> messages,
    required ChatParams params,
  }) async* {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final response = _mockResponses[_responseIndex % _mockResponses.length];
    _responseIndex++;

    final words = response.split(' ');
    for (final word in words) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield ChatResponseContent('$word ');
    }

    yield const ChatResponseUsage(inputTokens: 12, outputTokens: 24);
  }

  @override
  Future<ProviderHealth> checkHealth() async {
    return ProviderHealth(status: ProviderStatus.ready);
  }
}
