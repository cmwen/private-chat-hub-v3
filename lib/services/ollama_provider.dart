import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/chat_response.dart';
import '../models/message.dart';
import '../models/provider_model.dart';
import 'llm_provider.dart';

class OllamaProvider implements LlmProvider {
  String _baseUrl;
  ProviderStatus _status;
  final Dio _dio;

  OllamaProvider({String baseUrl = ''})
      : _baseUrl = baseUrl.trimRight().replaceAll(RegExp(r'/$'), ''),
        _status = baseUrl.trim().isEmpty
            ? ProviderStatus.unconfigured
            : ProviderStatus.offline,
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  @override
  String get providerId => 'ollama';

  @override
  String get displayName => 'Ollama';

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
    _baseUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    _status =
        _baseUrl.isEmpty ? ProviderStatus.unconfigured : ProviderStatus.offline;
  }

  @override
  Future<void> initialize() async {
    if (_baseUrl.isEmpty) {
      _status = ProviderStatus.unconfigured;
      return;
    }
    final health = await checkHealth();
    _status = health.status;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<ProviderHealth> checkHealth() async {
    if (_baseUrl.isEmpty) {
      return ProviderHealth(status: ProviderStatus.unconfigured);
    }
    try {
      final response = await _dio.get<dynamic>('$_baseUrl/api/tags');
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
    if (_status != ProviderStatus.ready) return [];
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('$_baseUrl/api/tags');
      final models = response.data?['models'] as List<dynamic>? ?? [];
      return models
          .whereType<Map<String, dynamic>>()
          .map(_modelFromJson)
          .toList();
    } on DioException {
      return [];
    }
  }

  AiModel _modelFromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final details = json['details'] as Map<String, dynamic>?;
    final paramSize = details?['parameter_size'] as String?;
    final display = _formatName(name);

    return AiModel(
      qualifiedId: 'ollama:$name',
      providerId: providerId,
      displayName: paramSize != null ? '$display ($paramSize)' : display,
      capabilities: const ModelCapabilities(
        streaming: true,
        systemPrompt: true,
      ),
    );
  }

  String _formatName(String name) {
    final base = name.replaceAll(':latest', '');
    return base
        .split(RegExp(r'[:\-_]'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  @override
  Future<AiModel?> getModelInfo(String modelId) async {
    final models = await listModels();
    try {
      return models.firstWhere((m) => m.qualifiedId == 'ollama:$modelId');
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
        message: 'Ollama is not connected (status: ${_status.name})',
      );
      return;
    }

    final body = {
      'model': modelId,
      'stream': true,
      'messages': [
        if (params.systemPrompt != null && params.systemPrompt!.isNotEmpty)
          {'role': 'system', 'content': params.systemPrompt},
        ...messages.map(
          (m) => {'role': m.role.name, 'content': m.content},
        ),
      ],
      'options': {
        'temperature': params.temperature,
        if (params.maxTokens != null) 'num_predict': params.maxTokens,
      },
    };

    try {
      final response = await _dio.post<ResponseBody>(
        '$_baseUrl/api/chat',
        data: body,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield const ChatResponseError(
          code: 'empty_stream',
          message: 'Empty response from Ollama',
        );
        return;
      }

      final buffer = StringBuffer();
      await for (final bytes in stream) {
        buffer.write(utf8.decode(bytes));
        final raw = buffer.toString();
        final lines = raw.split('\n');
        // Keep last partial line in buffer
        buffer
          ..clear()
          ..write(lines.last);

        for (final line in lines.sublist(0, lines.length - 1)) {
          if (line.trim().isEmpty) continue;
          Map<String, dynamic>? json;
          try {
            json = jsonDecode(line) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }
          final content = (json['message'] as Map<String, dynamic>?)?['content']
                  as String? ??
              '';
          if (content.isNotEmpty) yield ChatResponseContent(content);
          if (json['done'] == true) {
            final promptCount = json['prompt_eval_count'] as int? ?? 0;
            final evalCount = json['eval_count'] as int? ?? 0;
            yield ChatResponseUsage(
              inputTokens: promptCount,
              outputTokens: evalCount,
            );
          }
        }
      }

      // Flush any remaining buffer content
      final remaining = buffer.toString().trim();
      if (remaining.isNotEmpty) {
        try {
          final json = jsonDecode(remaining) as Map<String, dynamic>;
          final content = (json['message'] as Map<String, dynamic>?)?['content']
                  as String? ??
              '';
          if (content.isNotEmpty) yield ChatResponseContent(content);
        } catch (_) {}
      }
    } on DioException catch (e) {
      yield ChatResponseError(
        code: 'network_error',
        message: e.message ?? 'Network error',
      );
    }
  }
}
