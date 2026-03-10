enum ProviderType { local, selfHosted, cloud, gateway }

enum ProviderStatus { ready, unconfigured, offline, error, rateLimited }

class ProviderModel {
  final String id;
  final ProviderType type;
  final String displayName;
  final ProviderStatus status;
  final bool enabled;

  const ProviderModel({
    required this.id,
    required this.type,
    required this.displayName,
    this.status = ProviderStatus.unconfigured,
    this.enabled = true,
  });
}

class ModelCapabilities {
  final bool streaming;
  final bool vision;
  final bool toolCalling;
  final bool systemPrompt;

  const ModelCapabilities({
    this.streaming = false,
    this.vision = false,
    this.toolCalling = false,
    this.systemPrompt = true,
  });
}

class AiModel {
  final String qualifiedId;
  final String providerId;
  final String displayName;
  final int? contextWindow;
  final ModelCapabilities capabilities;

  const AiModel({
    required this.qualifiedId,
    required this.providerId,
    required this.displayName,
    this.contextWindow,
    this.capabilities = const ModelCapabilities(),
  });
}
