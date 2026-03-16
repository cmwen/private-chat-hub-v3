import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:private_chat_hub/providers/settings_provider.dart';
import 'package:private_chat_hub/screens/settings_screen.dart';

Future<SharedPreferences> _buildPrefs(
    {Map<String, Object> initialValues = const {}}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return SharedPreferences.getInstance();
}

void main() {
  group('Settings UI', () {
    testWidgets('shows chat history save controls', (tester) async {
      final prefs = await _buildPrefs();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chat History'), findsOneWidget);
      expect(find.text('When to save chat history'), findsOneWidget);
      expect(find.textContaining('Automatically'), findsOneWidget);
    });

    testWidgets('changes chat history save mode from settings dialog',
        (tester) async {
      final prefs = await _buildPrefs();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('When to save chat history'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Only when I tap Save'));
      await tester.pumpAndSettle();

      expect(prefs.getString('settings.chatHistorySaveMode'), 'manualOnly');
      expect(find.textContaining('Only when I tap Save'), findsOneWidget);
    });
  });
}
