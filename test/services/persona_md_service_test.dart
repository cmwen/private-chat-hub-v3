import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/services/persona_md_service.dart';

void main() {
  group('PersonaMdService', () {
    final service = PersonaMdService();

    test('parses valid persona.md frontmatter', () {
      const content = '''
---
name: Workspace Copilot
defaultModel: mock:default
defaultSystemPrompt: |
  You are a careful assistant.
  Prefer short answers.
---
# Ignored body
''';

      final persona = service.parse(content);

      expect(persona.name, 'Workspace Copilot');
      expect(persona.defaultModel, 'mock:default');
      expect(
        persona.defaultSystemPrompt,
        'You are a careful assistant.\nPrefer short answers.',
      );
    });

    test('loads folder-local persona.md from disk', () async {
      final directory =
          await Directory.systemTemp.createTemp('persona-md-test');
      final file = File('${directory.path}/persona.md');
      await file.writeAsString('''
---
name: Local Persona
---
''');

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final persona = await service.loadFromDirectory(directory.path);

      expect(persona, isNotNull);
      expect(persona!.name, 'Local Persona');
      expect(persona.filePath, file.path);
    });

    test('throws when closing delimiter is missing', () {
      expect(
        () => service.parse('''
---
name: Broken Persona
'''),
        throwsA(isA<PersonaMdParseException>()),
      );
    });

    test('throws when required name field is missing', () {
      expect(
        () => service.parse('''
---
defaultModel: mock:default
---
'''),
        throwsA(isA<PersonaMdParseException>()),
      );
    });
  });
}
