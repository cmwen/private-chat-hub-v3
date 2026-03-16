import 'conversation.dart';
import 'message.dart';

class ConversationHistorySnapshot {
  final Conversation conversation;
  final List<Message> messages;
  final DateTime savedAt;

  const ConversationHistorySnapshot({
    required this.conversation,
    required this.messages,
    required this.savedAt,
  });
}
