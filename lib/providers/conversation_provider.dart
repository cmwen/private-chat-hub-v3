import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/persona_document.dart';
import '../services/chat_history_file_service.dart';
import '../services/conversation_service.dart';
import '../services/database_service.dart';
import '../services/persona_md_service.dart';
import 'settings_provider.dart';

class NewConversationDefaults {
  final String preferredModelId;
  final String? systemPrompt;
  final PersonaDocument? personaDocument;

  const NewConversationDefaults({
    required this.preferredModelId,
    this.systemPrompt,
    this.personaDocument,
  });
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final chatHistoryFileServiceProvider = Provider<ChatHistoryFileService>((ref) {
  final historyDirectory = ref.watch(
    settingsProvider.select((settings) => settings.markdownHistoryDirectory),
  );
  return ChatHistoryFileService(
    baseDirectoryOverride:
        historyDirectory.trim().isEmpty ? null : historyDirectory.trim(),
  );
});

final personaMdServiceProvider = Provider<PersonaMdService>((ref) {
  return PersonaMdService();
});

final conversationServiceProvider = Provider<ConversationService>((ref) {
  return ConversationService(
    ref.watch(databaseServiceProvider),
    historyFileService: ref.watch(chatHistoryFileServiceProvider),
  );
});

final markdownHistoryDirectoryPathProvider =
    FutureProvider<String>((ref) async {
  return ref
      .watch(conversationServiceProvider)
      .resolveMarkdownHistoryDirectoryPath();
});

final personaDocumentProvider = FutureProvider<PersonaDocument?>((ref) async {
  final directoryPath =
      await ref.watch(markdownHistoryDirectoryPathProvider.future);
  return ref.watch(personaMdServiceProvider).loadFromDirectory(directoryPath);
});

final newConversationDefaultsProvider =
    FutureProvider<NewConversationDefaults>((ref) async {
  final settings = ref.watch(settingsProvider);
  PersonaDocument? persona;
  try {
    persona = await ref.watch(personaDocumentProvider.future);
  } catch (_) {
    persona = null;
  }
  return NewConversationDefaults(
    preferredModelId: persona?.defaultModel ?? settings.defaultModelId,
    systemPrompt: persona?.defaultSystemPrompt,
    personaDocument: persona,
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
    if (mounted) {
      state = convs;
    }
  }

  Future<Conversation> createConversation({
    String? title,
    required String modelId,
    String? systemPrompt,
  }) async {
    final conv = await _service.createConversation(
      title: title,
      modelId: modelId,
      systemPrompt: systemPrompt,
    );
    await _load();
    return conv;
  }

  Future<void> refresh() => _load();

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
    if (mounted) {
      state = msgs;
    }
  }

  Future<void> refresh() => _load();

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
