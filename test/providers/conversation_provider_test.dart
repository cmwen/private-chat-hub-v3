import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:private_chat_hub/providers/conversation_provider.dart';
import 'package:private_chat_hub/providers/settings_provider.dart';

void main() {
  group('Conversation provider persona defaults', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('conversation-provider');
      await File('${tempDir.path}/persona.md').writeAsString('''
---
name: Shared Workspace Persona
defaultModel: mock:fast
defaultSystemPrompt: |
  You are a workspace assistant.
  Prefer concise replies.
---
''');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loads new conversation defaults from persona.md in history directory',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings.defaultModelId': 'mock:default',
        'settings.markdownHistoryDirectory': tempDir.path,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final defaults =
          await container.read(newConversationDefaultsProvider.future);

      expect(defaults.preferredModelId, 'mock:fast');
      expect(
        defaults.systemPrompt,
        'You are a workspace assistant.\nPrefer concise replies.',
      );
      expect(defaults.personaDocument?.name, 'Shared Workspace Persona');
    });
  });
}
