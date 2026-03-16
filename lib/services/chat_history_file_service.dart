import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/conversation.dart';
import '../models/conversation_history_snapshot.dart';
import '../models/message.dart';
import '../utils/platform_utils.dart';

class ChatHistoryFileException implements FormatException {
  @override
  final String message;

  @override
  final dynamic source;

  @override
  final int? offset;

  const ChatHistoryFileException(this.message, {this.source, this.offset});

  @override
  String toString() => 'ChatHistoryFileException: $message';
}

class ChatHistoryFileService {
  final String? baseDirectoryOverride;

  const ChatHistoryFileService({this.baseDirectoryOverride});

  Future<ConversationHistorySnapshot> saveSnapshot({
    required Conversation conversation,
    required List<Message> messages,
  }) async {
    final snapshot = ConversationHistorySnapshot(
      conversation: conversation,
      messages: List<Message>.unmodifiable(messages),
      savedAt: DateTime.now(),
    );
    final file = await fileForConversation(conversation.id);
    await file.parent.create(recursive: true);

    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(_serializeSnapshot(snapshot), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);

    return snapshot;
  }

  Future<ConversationHistorySnapshot?> loadSnapshot(
      String conversationId) async {
    final file = await fileForConversation(conversationId);
    if (!await file.exists()) {
      return null;
    }

    return parseSnapshot(
      await file.readAsString(),
      sourcePath: file.path,
    );
  }

  Future<ConversationHistorySnapshot> loadSnapshotFromFile(
      String filePath) async {
    final file = File(filePath);
    return parseSnapshot(
      await file.readAsString(),
      sourcePath: file.path,
    );
  }

  Future<bool> exists(String conversationId) async {
    final file = await fileForConversation(conversationId);
    return file.exists();
  }

  Future<void> delete(String conversationId) async {
    final file = await fileForConversation(conversationId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> fileForConversation(String conversationId) async {
    final dir = await historyDirectory();
    return File(p.join(dir.path, '$conversationId.md'));
  }

  Future<Directory> historyDirectory() async {
    final path = await resolveHistoryDirectoryPath();
    return Directory(path);
  }

  Future<String> resolveHistoryDirectoryPath() async {
    if (baseDirectoryOverride != null &&
        baseDirectoryOverride!.trim().isNotEmpty) {
      return p.normalize(baseDirectoryOverride!.trim());
    }

    final root = isDesktopPlatform
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return p.join(root.path, 'history');
  }

  Future<List<File>> listConversationFiles() async {
    final dir = await historyDirectory();
    if (!await dir.exists()) {
      return const [];
    }

    final entries = await dir
        .list()
        .where(
          (entity) =>
              entity is File &&
              p.extension(entity.path).toLowerCase() == '.md' &&
              p.basename(entity.path).toLowerCase() != 'persona.md',
        )
        .cast<File>()
        .toList();
    entries.sort((a, b) => a.path.compareTo(b.path));
    return entries;
  }

  String _serializeSnapshot(ConversationHistorySnapshot snapshot) {
    final header = <String>[
      '# Chat Session: ${snapshot.conversation.title}',
      'Conversation ID: ${snapshot.conversation.id}',
      'Model: ${snapshot.conversation.modelId}',
      'Started: ${snapshot.conversation.createdAt.toIso8601String()}',
      'Updated: ${snapshot.conversation.updatedAt.toIso8601String()}',
      'Saved: ${snapshot.savedAt.toIso8601String()}',
      'Archived: ${snapshot.conversation.archived}',
    ];

    final systemPrompt = snapshot.conversation.systemPrompt;
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      header.add('System Prompt:');
      header.addAll(systemPrompt.split('\n').map((line) => '  $line'));
    }

    final buffer = StringBuffer()
      ..writeln(header.join('\n'))
      ..writeln('---');

    for (final message in snapshot.messages) {
      buffer.write(_serializeMessage(message));
    }

    return buffer.toString();
  }

  String _serializeMessage(Message message) {
    final metadata = <String>[];
    if (message.status != MessageStatus.sent) {
      metadata.add('Status: ${message.status.name}');
    }
    if (message.tokenUsage != null) {
      metadata.add('Input Tokens: ${message.tokenUsage!.inputTokens}');
      metadata.add('Output Tokens: ${message.tokenUsage!.outputTokens}');
    }
    if (message.costUsd != null) {
      metadata.add('Cost USD: ${message.costUsd}');
    }

    final buffer = StringBuffer()
      ..writeln(
          '## [${message.timestamp.toIso8601String()}] ${message.role.name}');

    for (final line in metadata) {
      buffer.writeln(line);
    }

    buffer.writeln();
    if (message.content.isNotEmpty) {
      buffer.write(message.content);
      if (!message.content.endsWith('\n')) {
        buffer.writeln();
      }
    }
    buffer.writeln('---');

    return buffer.toString();
  }

  ConversationHistorySnapshot parseSnapshot(
    String content, {
    String sourcePath = 'history.md',
  }) {
    final normalized = content.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final headerEnd = lines.indexOf('---');
    if (headerEnd <= 0) {
      throw ChatHistoryFileException(
        'History file is missing the header separator',
        source: sourcePath,
      );
    }

    final headerLines = lines.sublist(0, headerEnd);
    final conversation = _parseConversationHeader(headerLines, sourcePath);
    final blocks = _splitMessageBlocks(lines.sublist(headerEnd + 1));
    final messages = blocks
        .where((block) => block.any((line) => line.trim().isNotEmpty))
        .map((block) => _parseMessageBlock(conversation.id, block, sourcePath))
        .toList(growable: false);

    final savedAtLine = headerLines.firstWhere(
      (line) => line.startsWith('Saved: '),
      orElse: () => 'Saved: ${conversation.updatedAt.toIso8601String()}',
    );

    return ConversationHistorySnapshot(
      conversation: conversation,
      messages: messages,
      savedAt: DateTime.parse(savedAtLine.substring('Saved: '.length).trim()),
    );
  }

  Conversation _parseConversationHeader(List<String> lines, String sourcePath) {
    if (lines.isEmpty || !lines.first.startsWith('# Chat Session: ')) {
      throw ChatHistoryFileException(
        'History header must start with "# Chat Session:"',
        source: sourcePath,
      );
    }

    final title = lines.first.substring('# Chat Session: '.length).trim();
    String? conversationId;
    String? modelId;
    DateTime? createdAt;
    DateTime? updatedAt;
    bool archived = false;
    String? systemPrompt;

    for (var index = 1; index < lines.length; index++) {
      final line = lines[index];
      if (line == 'System Prompt:') {
        final promptLines = <String>[];
        while (index + 1 < lines.length &&
            (lines[index + 1].startsWith('  ') || lines[index + 1].isEmpty)) {
          index++;
          final promptLine = lines[index];
          promptLines.add(
            promptLine.startsWith('  ') ? promptLine.substring(2) : '',
          );
        }
        final prompt = promptLines.join('\n').trimRight();
        systemPrompt = prompt.isEmpty ? null : prompt;
        continue;
      }
      if (line.startsWith('Conversation ID: ')) {
        conversationId = line.substring('Conversation ID: '.length).trim();
      } else if (line.startsWith('Model: ')) {
        modelId = line.substring('Model: '.length).trim();
      } else if (line.startsWith('Started: ')) {
        createdAt = DateTime.parse(line.substring('Started: '.length).trim());
      } else if (line.startsWith('Updated: ')) {
        updatedAt = DateTime.parse(line.substring('Updated: '.length).trim());
      } else if (line.startsWith('Archived: ')) {
        archived =
            line.substring('Archived: '.length).trim().toLowerCase() == 'true';
      }
    }

    if (conversationId == null || conversationId.isEmpty) {
      throw ChatHistoryFileException(
        'History header is missing a conversation ID',
        source: sourcePath,
      );
    }
    if (modelId == null || modelId.isEmpty) {
      throw ChatHistoryFileException(
        'History header is missing a model ID',
        source: sourcePath,
      );
    }
    if (createdAt == null || updatedAt == null) {
      throw ChatHistoryFileException(
        'History header is missing timestamps',
        source: sourcePath,
      );
    }

    return Conversation(
      id: conversationId,
      title: title,
      modelId: modelId,
      systemPrompt: systemPrompt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archived: archived,
    );
  }

  List<List<String>> _splitMessageBlocks(List<String> lines) {
    final blocks = <List<String>>[];
    final current = <String>[];
    String? fenceMarker;

    for (final line in lines) {
      final nextFenceMarker = _nextFenceState(line, fenceMarker);
      final isSeparator = fenceMarker == null &&
          nextFenceMarker == null &&
          line.trim() == '---';

      fenceMarker = nextFenceMarker;
      if (isSeparator) {
        if (current.isNotEmpty) {
          blocks.add(List<String>.from(current));
          current.clear();
        }
        continue;
      }

      current.add(line);
    }

    if (current.isNotEmpty) {
      blocks.add(List<String>.from(current));
    }

    return blocks;
  }

  Message _parseMessageBlock(
    String conversationId,
    List<String> lines,
    String sourcePath,
  ) {
    final blockLines = List<String>.from(lines);
    while (blockLines.isNotEmpty && blockLines.first.trim().isEmpty) {
      blockLines.removeAt(0);
    }
    if (blockLines.isEmpty) {
      throw ChatHistoryFileException(
        'Encountered an empty message block',
        source: sourcePath,
      );
    }

    final heading = blockLines.first.trim();
    final match = RegExp(r'^## \[(.+)\] (\w+)$').firstMatch(heading);
    if (match == null) {
      throw ChatHistoryFileException(
        'Invalid message heading: $heading',
        source: sourcePath,
      );
    }

    final timestamp = DateTime.parse(match.group(1)!);
    final role = MessageRole.values.byName(match.group(2)!);

    var index = 1;
    MessageStatus status = MessageStatus.sent;
    int? inputTokens;
    int? outputTokens;
    double? costUsd;

    while (index < blockLines.length && blockLines[index].trim().isNotEmpty) {
      final line = blockLines[index];
      if (line.startsWith('Status: ')) {
        status = MessageStatus.values.byName(
          line.substring('Status: '.length).trim(),
        );
      } else if (line.startsWith('Input Tokens: ')) {
        inputTokens = int.parse(line.substring('Input Tokens: '.length).trim());
      } else if (line.startsWith('Output Tokens: ')) {
        outputTokens = int.parse(
          line.substring('Output Tokens: '.length).trim(),
        );
      } else if (line.startsWith('Cost USD: ')) {
        costUsd = double.parse(line.substring('Cost USD: '.length).trim());
      }
      index++;
    }

    if (index < blockLines.length && blockLines[index].trim().isEmpty) {
      index++;
    }
    final body = blockLines.sublist(index).join('\n').trimRight();

    return Message(
      id: '${conversationId}_${timestamp.microsecondsSinceEpoch}_${role.name}',
      conversationId: conversationId,
      role: role,
      content: body,
      status: status,
      tokenUsage: (inputTokens != null && outputTokens != null)
          ? TokenUsage(
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            )
          : null,
      costUsd: costUsd,
      timestamp: timestamp,
    );
  }

  String? _nextFenceState(String line, String? currentFenceMarker) {
    final trimmed = line.trimLeft();
    final match = RegExp(r'^(`{3,}|~{3,})').firstMatch(trimmed);
    if (match == null) {
      return currentFenceMarker;
    }

    final marker = match.group(1)!;
    if (currentFenceMarker == null) {
      return marker;
    }

    final expectedChar = currentFenceMarker[0];
    if (marker[0] == expectedChar &&
        marker.length >= currentFenceMarker.length) {
      return null;
    }
    return currentFenceMarker;
  }
}
