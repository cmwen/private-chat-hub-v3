import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_history_file_service.dart';
import '../services/conversation_service.dart';
import '../services/database_service.dart';
import 'settings_provider.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final chatHistoryFileServiceProvider = Provider<ChatHistoryFileService>((ref) {
  return const ChatHistoryFileService();
});

final conversationServiceProvider = Provider<ConversationService>((ref) {
  return ConversationService(
    ref.watch(databaseServiceProvider),
    historyFileService: ref.watch(chatHistoryFileServiceProvider),
  );
});

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref) {
  return ConversationsNotifier(ref, ref.watch(conversationServiceProvider));
});

class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  final Ref _ref;
  final ConversationService _service;

  ConversationsNotifier(this._ref, this._service) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final convs = await _service.getConversations();
    if (mounted) state = convs;
  }

  Future<Conversation> createConversation({
    String? title,
    String modelId = 'mock:default',
  }) async {
    final conv = await _service.createConversation(
      title: title,
      modelId: modelId,
    );
    await _load();
    return conv;
  }

  Future<void> deleteConversation(String id) async {
    await _service.deleteConversation(id);
    await _load();
    _ref.invalidate(savedHistoryExistsProvider(id));
  }

  Future<void> archiveConversation(String id) async {
    await _service.archiveConversation(id);
    await _load();
  }

  Future<void> renameConversation(String id, String newTitle) async {
    await _service.renameConversation(id, newTitle);
    await _load();
    await _maybeAutoSaveConversation(id);
  }

  Future<void> setConversationModel(String id, String modelId) async {
    await _service.setConversationModel(id, modelId);
    await _load();
    await _maybeAutoSaveConversation(id);
  }

  Future<void> _maybeAutoSaveConversation(String conversationId) async {
    final saveMode = _ref.read(settingsProvider).chatHistorySaveMode;
    if (saveMode != ChatHistorySaveMode.automatic) {
      return;
    }

    await _service.saveConversationSnapshot(conversationId);
    _ref.invalidate(savedHistoryExistsProvider(conversationId));
  }
}

final activeConversationIdProvider = StateProvider<String?>((ref) => null);

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, List<Message>, String>((
  ref,
  conversationId,
) {
  return MessagesNotifier(
    ref.watch(conversationServiceProvider),
    conversationId,
  );
});

class MessagesNotifier extends StateNotifier<List<Message>> {
  final ConversationService _service;
  final String _conversationId;

  MessagesNotifier(this._service, this._conversationId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final msgs = await _service.getMessages(_conversationId);
    if (mounted) state = msgs;
  }

  Future<void> addMessage(Message message) async {
    await _service.addMessage(message);
    await _load();
  }

  Future<void> updateMessage(Message message) async {
    await _service.updateMessage(message);
    await _load();
  }
}

final savedHistoryExistsProvider = FutureProvider.family<bool, String>((
  ref,
  conversationId,
) {
  return ref.watch(conversationServiceProvider).hasSavedHistory(conversationId);
});
