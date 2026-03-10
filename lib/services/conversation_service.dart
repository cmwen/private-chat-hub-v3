import '../models/conversation.dart';
import '../models/message.dart';
import 'database_service.dart';

class ConversationService {
  final DatabaseService _db;

  ConversationService(this._db);

  Future<List<Conversation>> getConversations({
    bool includeArchived = false,
  }) =>
      _db.getConversations(includeArchived: includeArchived);

  Future<Conversation?> getConversation(String id) =>
      _db.getConversation(id);

  Future<Conversation> createConversation({
    String? title,
    String modelId = 'mock:default',
    String? systemPrompt,
  }) async {
    final conv = Conversation.create(
      title: title,
      modelId: modelId,
      systemPrompt: systemPrompt,
    );
    await _db.insertConversation(conv);
    return conv;
  }

  Future<void> updateConversation(Conversation conversation) =>
      _db.updateConversation(conversation);

  Future<void> deleteConversation(String id) => _db.deleteConversation(id);

  Future<void> archiveConversation(String id) async {
    final conv = await _db.getConversation(id);
    if (conv != null) {
      await _db.updateConversation(conv.copyWith(archived: true));
    }
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final conv = await _db.getConversation(id);
    if (conv != null) {
      await _db.updateConversation(conv.copyWith(title: newTitle));
    }
  }

  Future<List<Message>> getMessages(String conversationId) =>
      _db.getMessages(conversationId);

  Future<void> addMessage(Message message) => _db.insertMessage(message);

  Future<void> updateMessage(Message message) => _db.updateMessage(message);
}
