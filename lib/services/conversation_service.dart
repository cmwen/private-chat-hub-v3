import 'dart:io';

import '../models/conversation.dart';
import '../models/conversation_history_snapshot.dart';
import '../models/history_file_index_entry.dart';
import '../models/message.dart';
import 'chat_history_file_service.dart';
import 'database_service.dart';

class ConversationService {
  final DatabaseService _db;
  final ChatHistoryFileService _historyFileService;

  Future<void>? _syncInFlight;

  ConversationService(
    this._db, {
    ChatHistoryFileService? historyFileService,
  }) : _historyFileService =
            historyFileService ?? const ChatHistoryFileService();

  Future<List<Conversation>> getConversations({
    bool includeArchived = false,
  }) async {
    await syncMarkdownHistoryIndex();
    return _db.getConversations(includeArchived: includeArchived);
  }

  Future<Conversation?> getConversation(String id) async {
    await syncMarkdownHistoryIndex();
    return _db.getConversation(id);
  }

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

  Future<void> setConversationModel(String id, String modelId) async {
    final conv = await _db.getConversation(id);
    if (conv != null) {
      await _db.updateConversation(conv.copyWith(modelId: modelId));
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    await syncMarkdownHistoryIndex();
    return _db.getMessages(conversationId);
  }

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
    final snapshot = await _historyFileService.saveSnapshot(
      conversation: conversation,
      messages: messages,
    );
    final file = await _historyFileService.fileForConversation(conversationId);
    final stat = await file.stat();
    await _db.replaceIndexedSnapshot(
      snapshot: snapshot,
      filePath: file.path,
      lastModifiedMs: stat.modified.millisecondsSinceEpoch,
      fileSize: stat.size,
    );
    return snapshot;
  }

  Future<ConversationHistorySnapshot?> loadSavedConversationSnapshot(
    String conversationId,
  ) {
    return _historyFileService.loadSnapshot(conversationId);
  }

  Future<bool> hasSavedHistory(String conversationId) {
    return _historyFileService.exists(conversationId);
  }

  Future<void> deleteSavedHistory(String conversationId) async {
    await _historyFileService.delete(conversationId);
    if (await _db.isConversationIndexed(conversationId)) {
      await _db.deleteIndexedConversation(conversationId);
    }
  }

  Future<String> resolveMarkdownHistoryDirectoryPath() {
    return _historyFileService.resolveHistoryDirectoryPath();
  }

  Future<void> syncMarkdownHistoryIndex({bool force = false}) async {
    if (!force && _syncInFlight != null) {
      return _syncInFlight!;
    }

    final future = _performMarkdownHistorySync();
    _syncInFlight = future.whenComplete(() {
      if (identical(_syncInFlight, future)) {
        _syncInFlight = null;
      }
    });
    return _syncInFlight!;
  }

  Future<void> _performMarkdownHistorySync() async {
    final files = await _historyFileService.listConversationFiles();
    final indexedEntries = await _db.getHistoryIndexEntries();
    final indexedByPath = {
      for (final entry in indexedEntries) entry.filePath: entry,
    };
    final seenPaths = <String>{};

    for (final file in files) {
      seenPaths.add(file.path);
      final stat = await file.stat();
      final indexed = indexedByPath[file.path];

      final unchanged = indexed != null &&
          indexed.lastModifiedMs == stat.modified.millisecondsSinceEpoch &&
          indexed.fileSize == stat.size;
      if (unchanged) {
        continue;
      }

      await _indexMarkdownHistoryFile(
        file: file,
        stat: stat,
        existingEntry: indexed,
      );
    }

    for (final entry in indexedEntries
        .where((entry) => !seenPaths.contains(entry.filePath))) {
      await _db.deleteIndexedConversation(entry.conversationId);
    }
  }

  Future<void> _indexMarkdownHistoryFile({
    required File file,
    required FileStat stat,
    required HistoryFileIndexEntry? existingEntry,
  }) async {
    try {
      final snapshot =
          await _historyFileService.loadSnapshotFromFile(file.path);
      await _db.replaceIndexedSnapshot(
        snapshot: snapshot,
        filePath: file.path,
        lastModifiedMs: stat.modified.millisecondsSinceEpoch,
        fileSize: stat.size,
      );
    } on FormatException {
      if (existingEntry != null) {
        await _db.deleteIndexedConversation(existingEntry.conversationId);
      }
    }
  }
}
