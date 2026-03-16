import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/conversation.dart';
import '../models/conversation_history_snapshot.dart';
import '../models/history_file_index_entry.dart';
import '../models/message.dart';
import '../utils/platform_utils.dart';

class DatabaseService {
  static const _dbName = 'private_chat_hub.db';
  static const _dbVersion = 2;

  /// Provide a custom factory/path for testing (e.g. sqflite_ffi in-memory).
  final DatabaseFactory? databaseFactoryOverride;
  final String? databasePathOverride;

  Database? _db;

  DatabaseService({
    this.databaseFactoryOverride,
    this.databasePathOverride,
  });

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final factory = databaseFactoryOverride ?? databaseFactory;
    final path = databasePathOverride ?? await _defaultPath();
    return factory.openDatabase(path, options: _buildOptions());
  }

  Future<String> _defaultPath() async {
    final dir = isDesktopPlatform
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  OpenDatabaseOptions _buildOptions() => OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id         TEXT PRIMARY KEY,
        title      TEXT NOT NULL,
        modelId    TEXT NOT NULL,
        systemPrompt TEXT,
        createdAt  TEXT NOT NULL,
        updatedAt  TEXT NOT NULL,
        archived   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id             TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        role           TEXT NOT NULL,
        content        TEXT NOT NULL,
        status         TEXT NOT NULL,
        inputTokens    INTEGER,
        outputTokens   INTEGER,
        costUsd        REAL,
        timestamp      TEXT NOT NULL,
        FOREIGN KEY (conversationId)
          REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE history_file_index (
        conversationId TEXT PRIMARY KEY,
        filePath       TEXT NOT NULL UNIQUE,
        lastModifiedMs INTEGER NOT NULL,
        fileSize       INTEGER NOT NULL,
        indexedAt      TEXT NOT NULL,
        FOREIGN KEY (conversationId)
          REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_messages_conv ON messages(conversationId)',
    );
    await db.execute(
      'CREATE INDEX idx_conversations_updated ON conversations(updatedAt DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_history_file_path ON history_file_index(filePath)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE history_file_index (
          conversationId TEXT PRIMARY KEY,
          filePath       TEXT NOT NULL UNIQUE,
          lastModifiedMs INTEGER NOT NULL,
          fileSize       INTEGER NOT NULL,
          indexedAt      TEXT NOT NULL,
          FOREIGN KEY (conversationId)
            REFERENCES conversations(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_history_file_path ON history_file_index(filePath)',
      );
    }
  }

  Future<List<Conversation>> getConversations({
    bool includeArchived = false,
  }) async {
    final db = await database;
    final rows = await db.query(
      'conversations',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'updatedAt DESC',
    );
    return rows.map(Conversation.fromJson).toList();
  }

  Future<Conversation?> getConversation(String id) async {
    final db = await database;
    final rows =
        await db.query('conversations', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return Conversation.fromJson(rows.first);
  }

  Future<void> insertConversation(Conversation conv) async {
    final db = await database;
    await db.insert(
      'conversations',
      conv.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateConversation(Conversation conv) async {
    final db = await database;
    await db.update(
      'conversations',
      conv.toJson(),
      where: 'id = ?',
      whereArgs: [conv.id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'history_file_index',
        where: 'conversationId = ?',
        whereArgs: [id],
      );
      await txn
          .delete('messages', where: 'conversationId = ?', whereArgs: [id]);
      await txn.delete('conversations', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<void> insertMessage(Message msg) async {
    final db = await database;
    await db.insert(
      'messages',
      _messageToRow(msg),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.execute(
      'UPDATE conversations SET updatedAt = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), msg.conversationId],
    );
  }

  Future<void> updateMessage(Message msg) async {
    final db = await database;
    await db.update(
      'messages',
      _messageToRow(msg),
      where: 'id = ?',
      whereArgs: [msg.id],
    );
  }

  Future<HistoryFileIndexEntry?> getHistoryIndexByPath(String filePath) async {
    final db = await database;
    final rows = await db.query(
      'history_file_index',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
    if (rows.isEmpty) {
      return null;
    }
    return HistoryFileIndexEntry.fromJson(rows.first);
  }

  Future<bool> isConversationIndexed(String conversationId) async {
    final db = await database;
    final rows = await db.query(
      'history_file_index',
      columns: const ['conversationId'],
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<HistoryFileIndexEntry>> getHistoryIndexEntries() async {
    final db = await database;
    final rows = await db.query(
      'history_file_index',
      orderBy: 'indexedAt DESC',
    );
    return rows.map(HistoryFileIndexEntry.fromJson).toList(growable: false);
  }

  Future<void> replaceIndexedSnapshot({
    required ConversationHistorySnapshot snapshot,
    required String filePath,
    required int lastModifiedMs,
    required int fileSize,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final existingByPath = await txn.query(
        'history_file_index',
        columns: const ['conversationId'],
        where: 'filePath = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      final previousConversationId = existingByPath.isNotEmpty
          ? existingByPath.first['conversationId'] as String
          : null;
      if (previousConversationId != null &&
          previousConversationId != snapshot.conversation.id) {
        await txn.delete(
          'messages',
          where: 'conversationId = ?',
          whereArgs: [previousConversationId],
        );
        await txn.delete(
          'conversations',
          where: 'id = ?',
          whereArgs: [previousConversationId],
        );
        await txn.delete(
          'history_file_index',
          where: 'conversationId = ?',
          whereArgs: [previousConversationId],
        );
      }
      await txn.insert(
        'conversations',
        snapshot.conversation.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'messages',
        where: 'conversationId = ?',
        whereArgs: [snapshot.conversation.id],
      );
      for (final message in snapshot.messages) {
        await txn.insert(
          'messages',
          _messageToRow(message),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        'history_file_index',
        HistoryFileIndexEntry(
          conversationId: snapshot.conversation.id,
          filePath: filePath,
          lastModifiedMs: lastModifiedMs,
          fileSize: fileSize,
          indexedAt: DateTime.now(),
        ).toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> deleteIndexedConversation(String conversationId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'history_file_index',
        where: 'conversationId = ?',
        whereArgs: [conversationId],
      );
      await txn.delete(
        'messages',
        where: 'conversationId = ?',
        whereArgs: [conversationId],
      );
      await txn.delete(
        'conversations',
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    });
  }

  Future<void> deleteIndexedConversationByPath(String filePath) async {
    final entry = await getHistoryIndexByPath(filePath);
    if (entry == null) {
      return;
    }
    await deleteIndexedConversation(entry.conversationId);
  }

  Map<String, dynamic> _messageToRow(Message msg) => {
        'id': msg.id,
        'conversationId': msg.conversationId,
        'role': msg.role.name,
        'content': msg.content,
        'status': msg.status.name,
        'inputTokens': msg.tokenUsage?.inputTokens,
        'outputTokens': msg.tokenUsage?.outputTokens,
        'costUsd': msg.costUsd,
        'timestamp': msg.timestamp.toIso8601String(),
      };

  Message _rowToMessage(Map<String, dynamic> row) {
    final inputTokens = row['inputTokens'] as int?;
    final outputTokens = row['outputTokens'] as int?;
    return Message(
      id: row['id'] as String,
      conversationId: row['conversationId'] as String,
      role: MessageRole.values.byName(row['role'] as String),
      content: row['content'] as String,
      status: MessageStatus.values
          .byName((row['status'] as String?) ?? MessageStatus.sent.name),
      tokenUsage: (inputTokens != null && outputTokens != null)
          ? TokenUsage(inputTokens: inputTokens, outputTokens: outputTokens)
          : null,
      costUsd: (row['costUsd'] as num?)?.toDouble(),
      timestamp: DateTime.parse(row['timestamp'] as String),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
