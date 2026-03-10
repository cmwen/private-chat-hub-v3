import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:private_chat_hub/services/conversation_service.dart';
import 'package:private_chat_hub/services/database_service.dart';
import 'package:private_chat_hub/models/message.dart';

DatabaseService _buildInMemoryDb() => DatabaseService(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: inMemoryDatabasePath,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late ConversationService service;
  late DatabaseService dbService;

  setUp(() {
    dbService = _buildInMemoryDb();
    service = ConversationService(dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('ConversationService', () {
    test('starts empty', () async {
      final convs = await service.getConversations();
      expect(convs, isEmpty);
    });

    test('createConversation persists and returns new conversation', () async {
      final conv = await service.createConversation(title: 'My Chat');
      expect(conv.title, 'My Chat');
      expect(conv.id, isNotEmpty);

      final all = await service.getConversations();
      expect(all.length, 1);
      expect(all.first.id, conv.id);
    });

    test('createConversation uses default title', () async {
      final conv = await service.createConversation();
      expect(conv.title, 'New Chat');
    });

    test('renameConversation updates title', () async {
      final conv = await service.createConversation(title: 'Old');
      await service.renameConversation(conv.id, 'New');
      final updated = await service.getConversation(conv.id);
      expect(updated?.title, 'New');
    });

    test('archiveConversation hides from default list', () async {
      final conv = await service.createConversation(title: 'To Archive');
      await service.archiveConversation(conv.id);

      final visible = await service.getConversations();
      expect(visible, isEmpty);

      final withArchived =
          await service.getConversations(includeArchived: true);
      expect(withArchived.length, 1);
      expect(withArchived.first.archived, isTrue);
    });

    test('deleteConversation removes it', () async {
      final conv = await service.createConversation();
      await service.deleteConversation(conv.id);
      final all = await service.getConversations();
      expect(all, isEmpty);
    });

    test('messages persist across calls', () async {
      final conv = await service.createConversation();
      final msg = Message.create(
        conversationId: conv.id,
        role: MessageRole.user,
        content: 'Hello',
        status: MessageStatus.sent,
      );
      await service.addMessage(msg);

      final messages = await service.getMessages(conv.id);
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello');
      expect(messages.first.role, MessageRole.user);
    });

    test('updateMessage persists changes', () async {
      final conv = await service.createConversation();
      final msg = Message.create(
        conversationId: conv.id,
        role: MessageRole.assistant,
        content: '',
        status: MessageStatus.sending,
      );
      await service.addMessage(msg);

      final updated = msg.copyWith(
        content: 'Full response',
        status: MessageStatus.sent,
      );
      await service.updateMessage(updated);

      final messages = await service.getMessages(conv.id);
      expect(messages.first.content, 'Full response');
      expect(messages.first.status, MessageStatus.sent);
    });

    test('deleteConversation cascades to messages', () async {
      final conv = await service.createConversation();
      await service.addMessage(Message.create(
        conversationId: conv.id,
        role: MessageRole.user,
        content: 'Hello',
      ));
      await service.deleteConversation(conv.id);

      final messages = await service.getMessages(conv.id);
      expect(messages, isEmpty);
    });

    test('messages ordered by timestamp', () async {
      final conv = await service.createConversation();
      await service.addMessage(Message.create(
        conversationId: conv.id,
        role: MessageRole.user,
        content: 'First',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.addMessage(Message.create(
        conversationId: conv.id,
        role: MessageRole.assistant,
        content: 'Second',
      ));

      final messages = await service.getMessages(conv.id);
      expect(messages[0].content, 'First');
      expect(messages[1].content, 'Second');
    });
  });
}
