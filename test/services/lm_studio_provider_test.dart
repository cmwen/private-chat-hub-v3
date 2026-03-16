import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:private_chat_hub/models/chat_response.dart';
import 'package:private_chat_hub/models/message.dart';
import 'package:private_chat_hub/models/provider_model.dart';
import 'package:private_chat_hub/services/llm_provider.dart';
import 'package:private_chat_hub/services/lm_studio_provider.dart';

void main() {
  group('LmStudioProvider', () {
    late HttpServer server;
    late LmStudioProvider provider;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      provider = LmStudioProvider(
        baseUrl: 'http://${server.address.address}:${server.port}',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('normalizes base URLs to the OpenAI-compatible /v1 endpoint', () {
      expect(
        LmStudioProvider.normalizeBaseUrl('localhost:1234'),
        LmStudioProvider.defaultBaseUrl,
      );
      expect(
        LmStudioProvider.normalizeBaseUrl('http://127.0.0.1:1234/'),
        'http://127.0.0.1:1234/v1',
      );
    });

    test('checks health and lists models from /v1/models', () async {
      server.listen((request) async {
        expect(request.uri.path, '/v1/models');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'data': [
              {
                'id': 'qwen2.5-7b-instruct',
                'context_length': 32768,
              },
            ],
          }),
        );
        await request.response.close();
      });

      final health = await provider.checkHealth();
      final models = await provider.listModels();

      expect(health.status, ProviderStatus.ready);
      expect(provider.currentStatus, ProviderStatus.ready);
      expect(models, hasLength(1));
      expect(models.single.qualifiedId, 'lmstudio:qwen2.5-7b-instruct');
      expect(models.single.contextWindow, 32768);
    });

    test('streams SSE chat completions', () async {
      server.listen((request) async {
        if (request.uri.path == '/v1/models') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'data': [
                {'id': 'qwen2.5-7b-instruct'},
              ],
            }),
          );
          await request.response.close();
          return;
        }

        expect(request.uri.path, '/v1/chat/completions');
        final payload = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        expect(payload['model'], 'qwen2.5-7b-instruct');
        expect(payload['stream'], isTrue);
        expect(payload['messages'], isA<List<dynamic>>());

        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
          charset: 'utf-8',
        );
        request.response.write(
          'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
        );
        await request.response.flush();
        request.response.write(
          'data: {"choices":[{"delta":{"content":" world"}}],"usage":{"prompt_tokens":11,"completion_tokens":7}}\n\n',
        );
        request.response.write('data: [DONE]\n\n');
        await request.response.close();
      });

      await provider.initialize();

      final responses = await provider
          .sendMessage(
            modelId: 'qwen2.5-7b-instruct',
            messages: [
              Message(
                id: 'm1',
                conversationId: 'c1',
                role: MessageRole.user,
                content: 'Say hello',
                timestamp: DateTime.utc(2025, 1, 1),
              ),
            ],
            params: const ChatParams(temperature: 0.4),
          )
          .toList();

      final text = responses
          .whereType<ChatResponseContent>()
          .map((event) => event.text)
          .join();
      final usage = responses.whereType<ChatResponseUsage>().single;

      expect(text, 'Hello world');
      expect(usage.inputTokens, 11);
      expect(usage.outputTokens, 7);
    });
  });
}
