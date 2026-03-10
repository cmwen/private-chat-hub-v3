import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/utils/model_id_utils.dart';

void main() {
  group('ModelIdUtils', () {
    group('isValid', () {
      test('returns true for well-formed qualified IDs', () {
        expect(ModelIdUtils.isValid('ollama:llama3.2'), isTrue);
        expect(ModelIdUtils.isValid('mock:default'), isTrue);
        expect(ModelIdUtils.isValid('local:gemma-2b'), isTrue);
      });

      test('returns false for empty string', () {
        expect(ModelIdUtils.isValid(''), isFalse);
      });

      test('returns false when no separator', () {
        expect(ModelIdUtils.isValid('ollama'), isFalse);
      });

      test('returns false when provider part is empty', () {
        expect(ModelIdUtils.isValid(':model'), isFalse);
      });

      test('returns false when model part is empty', () {
        expect(ModelIdUtils.isValid('provider:'), isFalse);
      });
    });

    group('extractProviderId', () {
      test('extracts provider from valid ID', () {
        expect(ModelIdUtils.extractProviderId('ollama:llama3.2'),
            equals('ollama'));
        expect(ModelIdUtils.extractProviderId('mock:default'), equals('mock'));
      });

      test('returns null for invalid ID', () {
        expect(ModelIdUtils.extractProviderId('invalid'), isNull);
        expect(ModelIdUtils.extractProviderId(''), isNull);
      });
    });

    group('extractModelId', () {
      test('extracts model from valid ID', () {
        expect(
            ModelIdUtils.extractModelId('ollama:llama3.2'), equals('llama3.2'));
        expect(ModelIdUtils.extractModelId('mock:default'), equals('default'));
      });

      test('returns null for invalid ID', () {
        expect(ModelIdUtils.extractModelId('invalid'), isNull);
      });

      test('handles colons in model name', () {
        // Only first colon is the separator
        expect(
          ModelIdUtils.extractModelId('ollama:qwen2:7b'),
          equals('qwen2:7b'),
        );
      });
    });

    group('build', () {
      test('combines provider and model with separator', () {
        expect(ModelIdUtils.build('ollama', 'llama3.2'),
            equals('ollama:llama3.2'));
        expect(ModelIdUtils.build('mock', 'default'), equals('mock:default'));
      });
    });

    group('displayName', () {
      test('capitalizes and formats model name', () {
        expect(ModelIdUtils.displayName('mock:default'), equals('Default'));
        expect(ModelIdUtils.displayName('ollama:llama3.2'), equals('Llama3.2'));
      });

      test('handles multi-word model names with hyphens', () {
        expect(ModelIdUtils.displayName('local:gemma-2b'), equals('Gemma 2b'));
      });
    });
  });
}
