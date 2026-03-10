import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/message.dart';

final _epoch = DateTime.utc(2024, 1, 1);

void main() {
  group('Message', () {
    test('copyWith updates fields', () {
      final original = Message(
        id: 'id1',
        conversationId: 'conv1',
        role: MessageRole.user,
        content: 'Hello',
        status: MessageStatus.sent,
        timestamp: _epoch,
      );

      final updated = original.copyWith(
        content: 'Updated',
        status: MessageStatus.failed,
      );

      expect(updated.id, equals('id1'));
      expect(updated.conversationId, equals('conv1'));
      expect(updated.role, equals(MessageRole.user));
      expect(updated.content, equals('Updated'));
      expect(updated.status, equals(MessageStatus.failed));
      expect(updated.timestamp, equals(_epoch));
    });

    test('toJson / fromJson round-trip', () {
      final original = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'Hello world',
        status: MessageStatus.sent,
        tokenUsage: const TokenUsage(inputTokens: 5, outputTokens: 10),
        timestamp: _epoch,
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.conversationId, equals(original.conversationId));
      expect(restored.role, equals(original.role));
      expect(restored.content, equals(original.content));
      expect(restored.status, equals(original.status));
      expect(restored.tokenUsage?.inputTokens, equals(5));
      expect(restored.tokenUsage?.outputTokens, equals(10));
    });

    test('TokenUsage.total sums tokens', () {
      const usage = TokenUsage(inputTokens: 10, outputTokens: 20);
      expect(usage.total, equals(30));
    });

    test('Message.create generates unique ids', () {
      final a = Message.create(
        conversationId: 'conv',
        role: MessageRole.user,
        content: 'a',
      );
      final b = Message.create(
        conversationId: 'conv',
        role: MessageRole.user,
        content: 'b',
      );
      expect(a.id, isNot(equals(b.id)));
    });

    test('MessageRole values include expected roles', () {
      expect(
          MessageRole.values,
          containsAll([
            MessageRole.user,
            MessageRole.assistant,
            MessageRole.system,
            MessageRole.tool,
          ]));
    });

    test('MessageStatus values include expected statuses', () {
      expect(
          MessageStatus.values,
          containsAll([
            MessageStatus.draft,
            MessageStatus.queued,
            MessageStatus.sending,
            MessageStatus.sent,
            MessageStatus.failed,
          ]));
    });
  });
}
