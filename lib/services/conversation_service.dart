import '../models/conversation.dart';
import '../models/conversation_history_snapshot.dart';
import '../models/message.dart';
import 'chat_history_file_service.dart';
import 'database_service.dart';

class ConversationService {
  final DatabaseService _db;
  final ChatHistoryFileService _historyFileService;

  ConversationService(
    this._db, {
    ChatHistoryFileService? historyFileService,
  }) : _historyFileService =
            historyFileService ?? const ChatHistoryFileService();

  Future<List<Conversation>> getConversations({
    bool includeArchived = false,
  }) =>
      _db.getConversations(includeArchived: includeArchived);

  Future<Conversation?> getConversation(String id) => _db.getConversation(id);

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

  Future<void> deleteConversation(String id) async {
    await _db.deleteConversation(id);
    await _historyFileService.delete(id);
  }

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

  Future<ConversationHistorySnapshot?> saveConversationSnapshot(
    String conversationId,
  ) async {
    final conversation = await _db.getConversation(conversationId);
    if (conversation == null) {
      return null;
    }

    final messages = await _db.getMessages(conversationId);
    return _historyFileService.saveSnapshot(
      conversation: conversation,
      messages: messages,
    );
  }

  Future<ConversationHistorySnapshot?> loadSavedConversationSnapshot(
    String conversationId,
  ) {
    return _historyFileService.loadSnapshot(conversationId);
  }

  Future<bool> hasSavedHistory(String conversationId) {
    return _historyFileService.exists(conversationId);
  }

  Future<void> deleteSavedHistory(String conversationId) {
    return _historyFileService.delete(conversationId);
  }
}
