import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // Initialize health-check asynchronously; status updates via checkHealth.
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

  /// Set to true when the user taps "Stop" during streaming.
  bool _cancelled = false;

  /// Holds a reference to the in-flight assistant message so
  /// [stopGeneration] can finalise it with the accumulated text.
  Message? _pendingAssistantMsg;

  /// Token usage captured from the last [onUsage] callback.
  TokenUsage? _pendingTokenUsage;

  ChatNotifier(this._chatService, this._conversationService, this._ref)
      : super(const ChatState());

  void selectModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
  }

  /// Cancels the current streaming response, saves whatever has been
  /// accumulated so far as the final message content, and returns to idle.
  void stopGeneration() {
    if (state.status != ChatStatus.streaming) return;
    _cancelled = true;

    final msg = _pendingAssistantMsg;
    if (msg != null) {
      final accumulated = state.streamingText;
      final completedMsg = msg.copyWith(
        content: accumulated.isEmpty ? '(stopped)' : accumulated,
        status: MessageStatus.sent,
      );
      // Fire-and-forget: persist the partial message to the DB.
      _ref
          .read(messagesProvider(msg.conversationId).notifier)
          .updateMessage(completedMsg);
    }

    state = state.copyWith(status: ChatStatus.idle, streamingText: '');
  }

  Future<void> sendMessage(String text, String conversationId) async {
    if (text.trim().isEmpty) return;
    if (state.status == ChatStatus.sending ||
        state.status == ChatStatus.streaming) {
      return;
    }

    // Reset per-request state.
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

    // Auto-title: rename "New Chat" conversations using the first 40 chars.
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
          if (_cancelled) return; // Stop appending when cancelled.
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

      // Only update state if the user hasn't already cancelled.
      if (_cancelled) return;

      final completedMsg = assistantMsg.copyWith(
        content: fullText,
        status: MessageStatus.sent,
        tokenUsage: _pendingTokenUsage,
      );
      await messagesNotifier.updateMessage(completedMsg);

      state = state.copyWith(status: ChatStatus.idle, streamingText: '');
    } on ChatServiceException catch (e) {
      if (_cancelled) return; // stopGeneration already handled the state.
      final failedMsg = assistantMsg.copyWith(
        content: 'Error: ${e.message}',
        status: MessageStatus.failed,
      );
      await messagesNotifier.updateMessage(failedMsg);
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.message,
        streamingText: '',
      );
    }
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
