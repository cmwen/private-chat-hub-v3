import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/persona_document.dart';

class PersonaMdParseException implements FormatException {
  @override
  final String message;

  @override
  final dynamic source;

  @override
  final int? offset;

  const PersonaMdParseException(this.message, {this.source, this.offset});

  @override
  String toString() => 'PersonaMdParseException: $message';
}

class PersonaMdService {
  static const fileName = 'persona.md';
  static const _supportedKeys = {
    'name',
    'defaultModel',
    'defaultSystemPrompt',
  };

  Future<PersonaDocument?> loadFromDirectory(String directoryPath) async {
    final file = File(p.join(directoryPath, fileName));
    if (!await file.exists()) {
      return null;
    }

    return parse(
      await file.readAsString(),
      filePath: file.path,
    );
  }

  PersonaDocument parse(String content, {String filePath = fileName}) {
    final lines = List<String>.from(
      const LineSplitter().convert(content.replaceAll('\r\n', '\n')),
    );
    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }
    if (lines.length < 3 || lines.first.trim() != '---') {
      throw PersonaMdParseException(
        'persona.md must start with a frontmatter block delimited by ---',
        source: filePath,
      );
    }

    final closingIndex = lines.indexWhere((line) => line.trim() == '---', 1);
    if (closingIndex == -1) {
      throw PersonaMdParseException(
        'persona.md is missing a closing --- delimiter',
        source: filePath,
      );
    }

    final values = <String, String>{};
    String? blockKey;
    final blockLines = <String>[];

    void flushBlock() {
      if (blockKey == null) return;
      values[blockKey!] = blockLines.join('\n').trimRight();
      blockKey = null;
      blockLines.clear();
    }

    for (var index = 1; index < closingIndex; index++) {
      final line = lines[index];
      final trimmed = line.trimRight();

      if (blockKey != null) {
        if (trimmed.isEmpty) {
          blockLines.add('');
          continue;
        }
        if (line.startsWith('  ') || line.startsWith('\t')) {
          blockLines.add(
            line.startsWith('  ') ? line.substring(2) : line.substring(1),
          );
          continue;
        }
        flushBlock();
      }

      if (trimmed.isEmpty) {
        continue;
      }

      final separatorIndex = trimmed.indexOf(':');
      if (separatorIndex <= 0) {
        throw PersonaMdParseException(
          'Invalid frontmatter line: $trimmed',
          source: filePath,
          offset: index,
        );
      }

      final key = trimmed.substring(0, separatorIndex).trim();
      final rawValue = trimmed.substring(separatorIndex + 1).trim();
      if (!_supportedKeys.contains(key)) {
        throw PersonaMdParseException(
          'Unsupported persona.md field: $key',
          source: filePath,
          offset: index,
        );
      }

      if (rawValue == '|') {
        blockKey = key;
        continue;
      }

      values[key] = _stripQuotes(rawValue);
    }

    flushBlock();

    final name = values['name']?.trim();
    if (name == null || name.isEmpty) {
      throw PersonaMdParseException(
        'persona.md must define a non-empty name field',
        source: filePath,
      );
    }

    final defaultModel = values['defaultModel']?.trim();
    final defaultSystemPrompt = values['defaultSystemPrompt'];

    return PersonaDocument(
      name: name,
      defaultModel:
          defaultModel == null || defaultModel.isEmpty ? null : defaultModel,
      defaultSystemPrompt:
          defaultSystemPrompt == null || defaultSystemPrompt.isEmpty
              ? null
              : defaultSystemPrompt,
      filePath: filePath,
    );
  }

  String _stripQuotes(String value) {
    if (value.length >= 2) {
      final first = value[0];
      final last = value[value.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        return value.substring(1, value.length - 1);
      }
    }
    return value;
  }
}
