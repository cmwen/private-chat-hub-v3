import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../utils/platform_utils.dart';

class DatabaseService {
  static const _dbName = 'private_chat_hub.db';
  static const _dbVersion = 1;

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

    await db.execute(
      'CREATE INDEX idx_messages_conv ON messages(conversationId)',
    );
    await db.execute(
      'CREATE INDEX idx_conversations_updated ON conversations(updatedAt DESC)',
    );
  }

  // ── Conversations ───────────────────────────────────────────────────────────

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
    if (rows.isEmpty) return null;
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
    await db.delete('messages', where: 'conversationId = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // ── Messages ────────────────────────────────────────────────────────────────

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

  // ── Helpers ─────────────────────────────────────────────────────────────────

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
