import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/chat_response.dart';
import '../models/message.dart';
import '../models/provider_model.dart';
import 'llm_provider.dart';

class LmStudioProvider implements LlmProvider {
  static const String defaultBaseUrl = 'http://localhost:1234/v1';

  String _baseUrl;
  ProviderStatus _status;
  final Dio _dio;

  LmStudioProvider({
    String baseUrl = defaultBaseUrl,
    Dio? dio,
  })  : _baseUrl = normalizeBaseUrl(baseUrl),
        _status = ProviderStatus.offline,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();
    if (normalized.isEmpty) {
      normalized = defaultBaseUrl;
    }

    if (!normalized.contains('://')) {
      normalized = 'http://$normalized';
    }

    normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    if (!normalized.endsWith('/v1')) {
      normalized = '$normalized/v1';
    }

    return normalized;
  }

  String get baseUrl => _baseUrl;

  @override
  String get providerId => 'lmstudio';

  @override
  String get displayName => 'LM Studio';

  @override
  ProviderType get providerType => ProviderType.selfHosted;

  @override
  bool get requiresApiKey => false;

  @override
  bool get requiresNetwork => true;

  @override
  bool get supportsStreaming => true;

  @override
  ProviderStatus get currentStatus => _status;

  void updateBaseUrl(String url) {
    _baseUrl = normalizeBaseUrl(url);
    _status = ProviderStatus.offline;
  }

  @override
  Future<void> initialize() async {
    final health = await checkHealth();
    _status = health.status;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<ProviderHealth> checkHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_baseUrl/models');
      if (response.statusCode == 200) {
        _status = ProviderStatus.ready;
        return ProviderHealth(status: ProviderStatus.ready);
      }

      _status = ProviderStatus.error;
      return ProviderHealth(
        status: ProviderStatus.error,
        errorMessage: 'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      _status = ProviderStatus.offline;
      return ProviderHealth(
        status: ProviderStatus.offline,
        errorMessage: e.message,
      );
    }
  }

  @override
  Future<List<AiModel>> listModels() async {
    if (_status != ProviderStatus.ready) {
      return [];
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>('$_baseUrl/models');
      final models = response.data?['data'] as List<dynamic>? ?? const [];
      return models
          .whereType<Map<String, dynamic>>()
          .map(_modelFromJson)
          .toList(growable: false);
    } on DioException {
      return [];
    }
  }

  AiModel _modelFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final contextWindow = (json['context_length'] as num?)?.toInt() ??
        (json['max_context_length'] as num?)?.toInt();

    return AiModel(
      qualifiedId: 'lmstudio:$id',
      providerId: providerId,
      displayName: id,
      contextWindow: contextWindow,
      capabilities: const ModelCapabilities(
        streaming: true,
        systemPrompt: true,
      ),
    );
  }

  @override
  Future<AiModel?> getModelInfo(String modelId) async {
    final models = await listModels();
    final qualifiedId =
        modelId.startsWith('$providerId:') ? modelId : '$providerId:$modelId';
    try {
      return models.firstWhere((m) => m.qualifiedId == qualifiedId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ChatResponse> sendMessage({
    required String modelId,
    required List<Message> messages,
    required ChatParams params,
  }) async* {
    if (_status != ProviderStatus.ready) {
      yield ChatResponseError(
        code: 'provider_not_ready',
        message: 'LM Studio is not connected (status: ${_status.name})',
      );
      return;
    }

    final body = {
      'model': modelId,
      'stream': true,
      'temperature': params.temperature,
      if (params.maxTokens != null) 'max_tokens': params.maxTokens,
      'messages': [
        if (params.systemPrompt != null && params.systemPrompt!.isNotEmpty)
          {'role': 'system', 'content': params.systemPrompt},
        ...messages.map(
          (message) => {
            'role': message.role.name,
            'content': message.content,
          },
        ),
      ],
    };

    try {
      final response = await _dio.post<ResponseBody>(
        '$_baseUrl/chat/completions',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield const ChatResponseError(
          code: 'empty_stream',
          message: 'Empty response from LM Studio',
        );
        return;
      }

      final buffer = StringBuffer();
      await for (final bytes in stream) {
        buffer.write(utf8.decode(bytes));
        final raw = buffer.toString();
        final events = raw.split('\n\n');

        buffer
          ..clear()
          ..write(events.last);

        for (final event in events.take(events.length - 1)) {
          final payload = _extractSsePayload(event);
          if (payload == null) {
            continue;
          }

          if (payload == '[DONE]') {
            continue;
          }

          Map<String, dynamic>? json;
          try {
            json = jsonDecode(payload) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }

          final usage = json['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            yield ChatResponseUsage(
              inputTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
              outputTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
            );
          }

          final choices = json['choices'] as List<dynamic>? ?? const [];
          for (final choice in choices.whereType<Map<String, dynamic>>()) {
            final delta = choice['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield ChatResponseContent(content);
            }
          }
        }
      }

      final remaining = _extractSsePayload(buffer.toString());
      if (remaining != null && remaining != '[DONE]') {
        try {
          final json = jsonDecode(remaining) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>? ?? const [];
          for (final choice in choices.whereType<Map<String, dynamic>>()) {
            final delta = choice['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield ChatResponseContent(content);
            }
          }
        } catch (_) {}
      }
    } on DioException catch (e) {
      yield ChatResponseError(
        code: 'network_error',
        message: e.message ?? 'Network error',
      );
    }
  }

  String? _extractSsePayload(String event) {
    final dataLines = event
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.startsWith('data:'))
        .map((line) => line.substring(5).trimLeft())
        .toList(growable: false);

    if (dataLines.isEmpty) {
      return null;
    }

    return dataLines.join('\n');
  }
}
