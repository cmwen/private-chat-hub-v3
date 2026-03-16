import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/models/chat_response.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/provider_model.dart';
import 'package:private_chat_hub/services/llm_provider.dart';
import 'package:private_chat_hub/services/provider_registry.dart';

class _FakeProvider implements LlmProvider {
  final String id;
  final ProviderStatus status;
  final List<AiModel> models;

  const _FakeProvider({
    required this.id,
    required this.status,
    this.models = const [],
  });

  @override
  String get providerId => id;

  @override
  String get displayName => id;

  @override
  ProviderType get providerType => ProviderType.local;

  @override
  bool get requiresApiKey => false;

  @override
  bool get requiresNetwork => false;

  @override
  bool get supportsStreaming => true;

  @override
  ProviderStatus get currentStatus => status;

  @override
  Future<void> dispose() async {}

  @override
  Future<AiModel?> getModelInfo(String modelId) async {
    try {
      return models.firstWhere((model) => model.qualifiedId == modelId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<List<AiModel>> listModels() async => models;

  @override
  Future<ProviderHealth> checkHealth() async => ProviderHealth(status: status);

  @override
  Stream<ChatResponse> sendMessage({
    required String modelId,
    required List<Message> messages,
    required ChatParams params,
  }) async* {}
}

void main() {
  group('ProviderRegistry', () {
    test(
        'falls back to a ready model when the preferred provider is unavailable',
        () async {
      final registry = ProviderRegistry();
      registry.register(
        const _FakeProvider(
          id: 'lmstudio',
          status: ProviderStatus.offline,
          models: [
            AiModel(
              qualifiedId: 'lmstudio:qwen',
              providerId: 'lmstudio',
              displayName: 'qwen',
            ),
          ],
        ),
      );

      final resolved = await registry.resolvePreferredModelId('lmstudio:qwen');

      expect(resolved, 'mock:default');
    });
  });
}
