import '../models/provider_model.dart';
import 'llm_provider.dart';
import 'mock_provider.dart';

class ProviderRegistry {
  final Map<String, LlmProvider> _providers = {};

  ProviderRegistry() {
    _registerDefaults();
  }

  void _registerDefaults() {
    register(MockProvider());
  }

  void register(LlmProvider provider) {
    _providers[provider.providerId] = provider;
  }

  LlmProvider? getProvider(String providerId) => _providers[providerId];

  List<LlmProvider> get allProviders => List.unmodifiable(_providers.values);

  List<LlmProvider> get readyProviders => _providers.values
      .where((p) => p.currentStatus == ProviderStatus.ready)
      .toList();

  /// Resolves a qualified model ID (e.g. "mock:default") to its provider.
  LlmProvider? resolveProvider(String qualifiedModelId) {
    final idx = qualifiedModelId.indexOf(':');
    if (idx < 0) return null;
    final providerId = qualifiedModelId.substring(0, idx);
    return _providers[providerId];
  }

  /// Resolves a qualified model ID to the raw model ID.
  String rawModelId(String qualifiedModelId) {
    final idx = qualifiedModelId.indexOf(':');
    if (idx < 0) return qualifiedModelId;
    return qualifiedModelId.substring(idx + 1);
  }

  Future<List<AiModel>> getAllModels() async {
    final results = <AiModel>[];
    for (final provider in _providers.values) {
      if (provider.currentStatus == ProviderStatus.ready) {
        final models = await provider.listModels();
        results.addAll(models);
      }
    }
    return results;
  }

  Future<void> initializeAll() async {
    for (final provider in _providers.values) {
      await provider.initialize();
    }
  }

  Future<void> disposeAll() async {
    for (final provider in _providers.values) {
      await provider.dispose();
    }
  }
}
