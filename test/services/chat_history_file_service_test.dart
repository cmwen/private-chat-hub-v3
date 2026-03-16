import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/services/chat_history_file_service.dart';

void main() {
  group('ChatHistoryFileService', () {
    late Directory tempDir;
    late ChatHistoryFileService service;
    late Conversation conversation;
    late List<Message> messages;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chat-history-test');
      service = ChatHistoryFileService(baseDirectoryOverride: tempDir.path);
      conversation = Conversation(
        id: 'conversation-123',
        title: 'Markdown Session',
        modelId: 'mock:default',
        systemPrompt: 'Be helpful.',
        createdAt: DateTime.parse('2025-01-01T10:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T10:05:00Z'),
      );
      messages = [
        Message(
          id: 'm1',
          conversationId: conversation.id,
          role: MessageRole.user,
          content: 'Show me a fence-aware example.',
          timestamp: DateTime.parse('2025-01-01T10:01:00Z'),
        ),
        Message(
          id: 'm2',
          conversationId: conversation.id,
          role: MessageRole.assistant,
          content: '''
Here is a code sample:

```dart
void main() {
  print('--- should stay inside the code fence ---');
}
```
''',
          status: MessageStatus.failed,
          tokenUsage: const TokenUsage(inputTokens: 12, outputTokens: 34),
          costUsd: 0.42,
          timestamp: DateTime.parse('2025-01-01T10:02:00Z'),
        ),
      ];
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('round-trips markdown history files without splitting fenced code',
        () async {
      final savedSnapshot = await service.saveSnapshot(
        conversation: conversation,
        messages: messages,
      );
      final loadedSnapshot = await service.loadSnapshot(conversation.id);

      expect(savedSnapshot.savedAt, isNotNull);
      expect(loadedSnapshot, isNotNull);
      expect(loadedSnapshot!.conversation.title, conversation.title);
      expect(loadedSnapshot.conversation.systemPrompt, 'Be helpful.');
      expect(loadedSnapshot.messages.length, 2);
      expect(
        loadedSnapshot.messages[1].content,
        contains('--- should stay inside the code fence ---'),
      );
      expect(loadedSnapshot.messages[1].status, MessageStatus.failed);
      expect(loadedSnapshot.messages[1].tokenUsage?.total, 46);
      expect(loadedSnapshot.messages[1].costUsd, 0.42);
    });

    test('exists and delete follow saved file lifecycle', () async {
      expect(await service.exists(conversation.id), isFalse);

      await service.saveSnapshot(
        conversation: conversation,
        messages: messages,
      );
      expect(await service.exists(conversation.id), isTrue);

      await service.delete(conversation.id);
      expect(await service.exists(conversation.id), isFalse);
    });
  });
}
