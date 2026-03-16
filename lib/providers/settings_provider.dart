import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatHistorySaveMode { automatic, askBeforeSaving, manualOnly }

extension ChatHistorySaveModeX on ChatHistorySaveMode {
  String get label {
    switch (this) {
      case ChatHistorySaveMode.automatic:
        return 'Automatically';
      case ChatHistorySaveMode.askBeforeSaving:
        return 'Ask before saving';
      case ChatHistorySaveMode.manualOnly:
        return 'Only when I tap Save';
    }
  }

  String get description {
    switch (this) {
      case ChatHistorySaveMode.automatic:
        return 'Save chat history to this device as you chat.';
      case ChatHistorySaveMode.askBeforeSaving:
        return 'Prompt Save, Discard, or Cancel when leaving a chat.';
      case ChatHistorySaveMode.manualOnly:
        return 'Keep chats temporary until you choose Save.';
    }
  }
}

class AppSettings {
  final bool streamingEnabled;
  final bool markdownEnabled;
  final double temperature;
  final String defaultModelId;
  final String ollamaBaseUrl;
  final ChatHistorySaveMode chatHistorySaveMode;

  const AppSettings({
    this.streamingEnabled = true,
    this.markdownEnabled = true,
    this.temperature = 0.7,
    this.defaultModelId = 'mock:default',
    this.ollamaBaseUrl = '',
    this.chatHistorySaveMode = ChatHistorySaveMode.automatic,
  });

  AppSettings copyWith({
    bool? streamingEnabled,
    bool? markdownEnabled,
    double? temperature,
    String? defaultModelId,
    String? ollamaBaseUrl,
    ChatHistorySaveMode? chatHistorySaveMode,
  }) {
    return AppSettings(
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      markdownEnabled: markdownEnabled ?? this.markdownEnabled,
      temperature: temperature ?? this.temperature,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      chatHistorySaveMode: chatHistorySaveMode ?? this.chatHistorySaveMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  static const _kStreaming = 'settings.streamingEnabled';
  static const _kMarkdown = 'settings.markdownEnabled';
  static const _kTemperature = 'settings.temperature';
  static const _kDefaultModel = 'settings.defaultModelId';
  static const _kOllamaUrl = 'settings.ollamaBaseUrl';
  static const _kChatHistorySaveMode = 'settings.chatHistorySaveMode';

  SettingsNotifier(this._prefs) : super(_load(_prefs));

  static AppSettings _load(SharedPreferences prefs) => AppSettings(
        streamingEnabled: prefs.getBool(_kStreaming) ?? true,
        markdownEnabled: prefs.getBool(_kMarkdown) ?? true,
        temperature: prefs.getDouble(_kTemperature) ?? 0.7,
        defaultModelId: prefs.getString(_kDefaultModel) ?? 'mock:default',
        ollamaBaseUrl: prefs.getString(_kOllamaUrl) ?? '',
        chatHistorySaveMode: _parseChatHistorySaveMode(
          prefs.getString(_kChatHistorySaveMode),
        ),
      );

  static ChatHistorySaveMode _parseChatHistorySaveMode(String? rawValue) {
    for (final mode in ChatHistorySaveMode.values) {
      if (mode.name == rawValue) {
        return mode;
      }
    }
    return ChatHistorySaveMode.automatic;
  }

  Future<void> setStreaming(bool value) async {
    await _prefs.setBool(_kStreaming, value);
    state = state.copyWith(streamingEnabled: value);
  }

  Future<void> setMarkdown(bool value) async {
    await _prefs.setBool(_kMarkdown, value);
    state = state.copyWith(markdownEnabled: value);
  }

  Future<void> setTemperature(double value) async {
    final clamped = value.clamp(0.0, 2.0);
    await _prefs.setDouble(_kTemperature, clamped);
    state = state.copyWith(temperature: clamped);
  }

  Future<void> setDefaultModel(String modelId) async {
    await _prefs.setString(_kDefaultModel, modelId);
    state = state.copyWith(defaultModelId: modelId);
  }

  Future<void> setOllamaBaseUrl(String url) async {
    final trimmed = url.trim();
    await _prefs.setString(_kOllamaUrl, trimmed);
    state = state.copyWith(ollamaBaseUrl: trimmed);
  }

  Future<void> setChatHistorySaveMode(ChatHistorySaveMode mode) async {
    await _prefs.setString(_kChatHistorySaveMode, mode.name);
    state = state.copyWith(chatHistorySaveMode: mode);
  }
}

/// Override this provider before running the app (see main.dart).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
