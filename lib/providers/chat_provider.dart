import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';
import '../services/mock_provider.dart';
import '../services/ollama_provider.dart';
import '../services/provider_registry.dart';
import 'conversation_provider.dart';
import 'settings_provider.dart';

final ollamaProviderInstance = Provider<OllamaProvider>((ref) {
  final url = ref.watch(settingsProvider.select((s) => s.ollamaBaseUrl));
  final provider = OllamaProvider(baseUrl: url);
  Future.microtask(provider.initialize);
  return provider;
});

final providerRegistryProvider = Provider<ProviderRegistry>((ref) {
  final registry = ProviderRegistry();
  registry.register(MockProvider());
  registry.register(ref.watch(ollamaProviderInstance));
  return registry;
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(providerRegistryProvider));
});

enum ChatStatus { idle, sending, streaming, error }

class ChatState {
  final ChatStatus status;
  final String? errorMessage;
  final String streamingText;
  final String selectedModelId;

  const ChatState({
    this.status = ChatStatus.idle,
    this.errorMessage,
    this.streamingText = '',
    this.selectedModelId = 'mock:default',
  });

  ChatState copyWith({
    ChatStatus? status,
    String? errorMessage,
    String? streamingText,
    String? selectedModelId,
  }) {
    return ChatState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      streamingText: streamingText ?? this.streamingText,
      selectedModelId: selectedModelId ?? this.selectedModelId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final ConversationService _conversationService;
  final Ref _ref;

  bool _cancelled = false;
  Message? _pendingAssistantMsg;
  TokenUsage? _pendingTokenUsage;

  ChatNotifier(this._chatService, this._conversationService, this._ref)
      : super(const ChatState());

  void selectModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
  }

  void stopGeneration() {
    if (state.status != ChatStatus.streaming) return;
    _cancelled = true;
    final stoppedText = state.streamingText;

    final msg = _pendingAssistantMsg;
    if (msg != null) {
      unawaited(_finalizeStoppedMessage(msg, stoppedText));
    }

    state = state.copyWith(status: ChatStatus.idle, streamingText: '');
  }

  Future<void> sendMessage(String text, String conversationId) async {
    if (text.trim().isEmpty) return;
    if (state.status == ChatStatus.sending ||
        state.status == ChatStatus.streaming) {
      return;
    }

    _cancelled = false;
    _pendingTokenUsage = null;
    _pendingAssistantMsg = null;

    final userMsg = Message.create(
      conversationId: conversationId,
      role: MessageRole.user,
      content: text.trim(),
      status: MessageStatus.sent,
    );

    final messagesNotifier =
        _ref.read(messagesProvider(conversationId).notifier);
    await messagesNotifier.addMessage(userMsg);

    final conv = await _conversationService.getConversation(conversationId);
    if (conv != null && conv.title == 'New Chat') {
      final trimmed = text.trim();
      final newTitle =
          trimmed.length > 40 ? '${trimmed.substring(0, 40)}...' : trimmed;
      await _ref
          .read(conversationsProvider.notifier)
          .renameConversation(conversationId, newTitle);
    }

    final assistantMsg = Message.create(
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.sending,
    );
    await messagesNotifier.addMessage(assistantMsg);
    _pendingAssistantMsg = assistantMsg;

    state = state.copyWith(status: ChatStatus.streaming, streamingText: '');

    try {
      final history = await _conversationService.getMessages(conversationId);
      final settings = _ref.read(settingsProvider);

      final fullText = await _chatService.sendMessage(
        conversationId: conversationId,
        modelId: state.selectedModelId,
        history: history,
        userText: text,
        temperature: settings.temperature,
        onChunk: (chunk) {
          if (_cancelled) return;
          state = state.copyWith(
            streamingText: state.streamingText + chunk,
          );
        },
        onUsage: (inputTokens, outputTokens) {
          _pendingTokenUsage = TokenUsage(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          );
        },
      );

      if (_cancelled) return;

      final completedMsg = assistantMsg.copyWith(
        content: fullText,
        status: MessageStatus.sent,
        tokenUsage: _pendingTokenUsage,
      );
      await messagesNotifier.updateMessage(completedMsg);
      await _maybeAutoSaveConversation(conversationId);

      state = state.copyWith(status: ChatStatus.idle, streamingText: '');
      _pendingAssistantMsg = null;
    } on ChatServiceException catch (e) {
      if (_cancelled) return;
      final failedMsg = assistantMsg.copyWith(
        content: 'Error: ${e.message}',
        status: MessageStatus.failed,
        tokenUsage: _pendingTokenUsage,
      );
      await messagesNotifier.updateMessage(failedMsg);
      await _maybeAutoSaveConversation(conversationId);
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.message,
        streamingText: '',
      );
      _pendingAssistantMsg = null;
    }
  }

  Future<void> _finalizeStoppedMessage(
    Message message,
    String stoppedText,
  ) async {
    final completedMsg = message.copyWith(
      content: stoppedText.isEmpty ? '(stopped)' : stoppedText,
      status: MessageStatus.sent,
      tokenUsage: _pendingTokenUsage,
    );
    await _ref
        .read(messagesProvider(message.conversationId).notifier)
        .updateMessage(completedMsg);
    await _maybeAutoSaveConversation(message.conversationId);
    _pendingAssistantMsg = null;
  }

  Future<void> _maybeAutoSaveConversation(String conversationId) async {
    final saveMode = _ref.read(settingsProvider).chatHistorySaveMode;
    if (saveMode != ChatHistorySaveMode.automatic) {
      return;
    }

    await _conversationService.saveConversationSnapshot(conversationId);
    _ref.invalidate(savedHistoryExistsProvider(conversationId));
  }

  void clearError() {
    state = state.copyWith(status: ChatStatus.idle, errorMessage: null);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final conversationService = ref.watch(conversationServiceProvider);
  return ChatNotifier(chatService, conversationService, ref);
});
