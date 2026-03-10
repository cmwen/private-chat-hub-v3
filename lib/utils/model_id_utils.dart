/// Utilities for working with qualified model IDs (e.g. "ollama:llama3.2").
class ModelIdUtils {
  const ModelIdUtils._();

  static const String separator = ':';

  /// Returns true if the given string is a valid qualified model ID.
  static bool isValid(String qualifiedId) {
    if (qualifiedId.isEmpty) return false;
    final idx = qualifiedId.indexOf(separator);
    if (idx <= 0) return false;
    final providerId = qualifiedId.substring(0, idx);
    final modelId = qualifiedId.substring(idx + 1);
    return providerId.isNotEmpty && modelId.isNotEmpty;
  }

  /// Extracts the provider ID from a qualified model ID.
  /// Returns null if the ID is not valid.
  static String? extractProviderId(String qualifiedId) {
    if (!isValid(qualifiedId)) return null;
    return qualifiedId.substring(0, qualifiedId.indexOf(separator));
  }

  /// Extracts the raw model ID from a qualified model ID.
  /// Returns null if the ID is not valid.
  static String? extractModelId(String qualifiedId) {
    if (!isValid(qualifiedId)) return null;
    return qualifiedId.substring(qualifiedId.indexOf(separator) + 1);
  }

  /// Builds a qualified model ID from provider ID and model ID.
  static String build(String providerId, String modelId) {
    return '$providerId$separator$modelId';
  }

  /// Returns a display-friendly name for a qualified model ID.
  static String displayName(String qualifiedId) {
    final modelId = extractModelId(qualifiedId) ?? qualifiedId;
    return modelId
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
