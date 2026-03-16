import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:private_chat_hub/providers/settings_provider.dart';

void main() {
  group('SettingsProvider', () {
    test('loads and persists chat history save mode', () async {
      SharedPreferences.setMockInitialValues({
        'settings.chatHistorySaveMode': 'manualOnly',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(settingsProvider).chatHistorySaveMode,
        ChatHistorySaveMode.manualOnly,
      );

      await container
          .read(settingsProvider.notifier)
          .setChatHistorySaveMode(ChatHistorySaveMode.askBeforeSaving);

      expect(
        container.read(settingsProvider).chatHistorySaveMode,
        ChatHistorySaveMode.askBeforeSaving,
      );
      expect(
        prefs.getString('settings.chatHistorySaveMode'),
        'askBeforeSaving',
      );
    });
  });
}
