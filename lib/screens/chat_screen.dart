import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/provider_model.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/provider_registry.dart';
import '../utils/platform_utils.dart';
import '../widgets/chat_input.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_chip.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

enum _LeaveConversationAction { save, discard, cancel }

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _ensureConversation() async {
    var activeId = ref.read(activeConversationIdProvider);
    if (activeId == null) {
      final preferredModelId = ref.read(chatProvider).selectedModelId;
      final selectedModelId = await ref
          .read(providerRegistryProvider)
          .resolvePreferredModelId(preferredModelId);
      final conv =
          await ref.read(conversationsProvider.notifier).createConversation(
                title: 'New Chat',
                modelId: selectedModelId,
              );
      if (mounted) {
        ref.read(activeConversationIdProvider.notifier).state = conv.id;
        ref.read(chatProvider.notifier).selectModel(selectedModelId);
        ref.invalidate(savedHistoryExistsProvider(conv.id));
      }
      activeId = conv.id;
    }
    return activeId;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _handleNewChatRequested() async {
    final shouldContinue = await _confirmConversationLeave();
    if (!shouldContinue) {
      return false;
    }

    final preferredModelId = ref.read(chatProvider).selectedModelId;
    final selectedModelId = await ref
        .read(providerRegistryProvider)
        .resolvePreferredModelId(preferredModelId);
    final conv =
        await ref.read(conversationsProvider.notifier).createConversation(
              title: 'New Chat',
              modelId: selectedModelId,
            );
    if (!mounted) {
      return false;
    }

    ref.read(activeConversationIdProvider.notifier).state = conv.id;
    ref.read(chatProvider.notifier).selectModel(selectedModelId);
    ref.invalidate(savedHistoryExistsProvider(conv.id));
    return true;
  }

  Future<bool> _handleConversationSelected(String conversationId) async {
    final activeId = ref.read(activeConversationIdProvider);
    if (activeId == conversationId) {
      return true;
    }

    final shouldContinue = await _confirmConversationLeave();
    if (!shouldContinue || !mounted) {
      return false;
    }

    ref.read(activeConversationIdProvider.notifier).state = conversationId;
    Conversation? conversation;
    for (final item in ref.read(conversationsProvider)) {
      if (item.id == conversationId) {
        conversation = item;
        break;
      }
    }
    if (conversation != null) {
      ref.read(chatProvider.notifier).selectModel(conversation.modelId);
    }
    return true;
  }

  Future<void> _saveCurrentConversationSnapshot({
    bool showFeedback = true,
  }) async {
    final activeId = ref.read(activeConversationIdProvider);
    if (activeId == null) {
      if (showFeedback && mounted) {
        _showSnackBar('Start a conversation before saving history.');
      }
      return;
    }

    final snapshot = await ref
        .read(conversationServiceProvider)
        .saveConversationSnapshot(activeId);
    ref.invalidate(savedHistoryExistsProvider(activeId));

    if (!mounted || !showFeedback) {
      return;
    }

    if (snapshot == null) {
      _showSnackBar('Unable to save chat history.');
      return;
    }

    _showSnackBar('Chat history saved.');
  }

  Future<bool> _confirmConversationLeave() async {
    final chatState = ref.read(chatProvider);
    if (chatState.status == ChatStatus.streaming ||
        chatState.status == ChatStatus.sending) {
      if (mounted) {
        _showSnackBar('Finish or stop the current response before leaving.');
      }
      return false;
    }

    final settings = ref.read(settingsProvider);
    if (settings.chatHistorySaveMode != ChatHistorySaveMode.askBeforeSaving) {
      return true;
    }

    final activeId = ref.read(activeConversationIdProvider);
    if (activeId == null) {
      return true;
    }

    final conversationService = ref.read(conversationServiceProvider);
    final messages = await conversationService.getMessages(activeId);
    if (messages.isEmpty) {
      return true;
    }

    final hasSavedHistory = await conversationService.hasSavedHistory(activeId);
    if (!mounted) {
      return false;
    }

    final action = await showDialog<_LeaveConversationAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save chat before leaving?'),
        content: Text(
          hasSavedHistory
              ? 'This chat already has a saved markdown history file. Save again to update it before leaving?'
              : 'This chat is still temporary. Save it as a markdown (.md) history file before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              _LeaveConversationAction.cancel,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              _LeaveConversationAction.discard,
            ),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              _LeaveConversationAction.save,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    switch (action) {
      case _LeaveConversationAction.save:
        await _saveCurrentConversationSnapshot(showFeedback: false);
        return true;
      case _LeaveConversationAction.discard:
        return true;
      case _LeaveConversationAction.cancel:
      case null:
        return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final activeId = ref.watch(activeConversationIdProvider);
    final messages =
        activeId != null ? ref.watch(messagesProvider(activeId)) : <Message>[];
    final showDesktopLayout = isWideLayout(MediaQuery.sizeOf(context).width);
    final settings = ref.watch(settingsProvider);
    final hasSavedHistory = activeId == null
        ? const AsyncValue<bool>.data(false)
        : ref.watch(savedHistoryExistsProvider(activeId));

    if (chatState.status == ChatStatus.streaming) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: ModelChip(
          modelId: chatState.selectedModelId,
          onTap: () => _showModelPicker(context),
        ),
        actions: [
          if (settings.chatHistorySaveMode != ChatHistorySaveMode.automatic)
            IconButton(
              icon: Icon(
                hasSavedHistory.value == true
                    ? Icons.save_as_rounded
                    : Icons.save_outlined,
              ),
              tooltip: hasSavedHistory.value == true
                  ? 'Save history again'
                  : 'Save history',
              onPressed: activeId == null
                  ? null
                  : () => _saveCurrentConversationSnapshot(),
            ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: _handleNewChatRequested,
          ),
        ],
      ),
      drawer: showDesktopLayout
          ? null
          : ConversationDrawer(
              onNewChatRequested: _handleNewChatRequested,
              onConversationSelected: _handleConversationSelected,
            ),
      body: Row(
        children: [
          if (showDesktopLayout) ...[
            SizedBox(
              width: 320,
              child: ConversationDrawer(
                embedded: true,
                onNewChatRequested: _handleNewChatRequested,
                onConversationSelected: _handleConversationSelected,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
          Expanded(
            child: _ChatPane(
              chatState: chatState,
              messages: messages,
              scrollController: _scrollController,
              showMarkdown: settings.markdownEnabled,
              onSendSample: (text) async {
                final convId = await _ensureConversation();
                if (mounted) {
                  ref.read(chatProvider.notifier).sendMessage(text, convId);
                }
              },
              onSend: (text) async {
                final convId = await _ensureConversation();
                if (mounted) {
                  ref.read(chatProvider.notifier).sendMessage(text, convId);
                }
              },
              onDismissError: () =>
                  ref.read(chatProvider.notifier).clearError(),
              onStop: () => ref.read(chatProvider.notifier).stopGeneration(),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelPicker(BuildContext context) {
    if (isWideLayout(MediaQuery.sizeOf(context).width)) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: const _ModelPickerContent(),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => const SafeArea(child: _ModelPickerContent()),
    );
  }
}

class _ChatPane extends StatelessWidget {
  final ChatState chatState;
  final List<Message> messages;
  final ScrollController scrollController;
  final bool showMarkdown;
  final void Function(String text) onSendSample;
  final void Function(String text) onSend;
  final VoidCallback onDismissError;
  final VoidCallback onStop;

  const _ChatPane({
    required this.chatState,
    required this.messages,
    required this.scrollController,
    required this.showMarkdown,
    required this.onSendSample,
    required this.onSend,
    required this.onDismissError,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (chatState.status == ChatStatus.error &&
            chatState.errorMessage != null)
          MaterialBanner(
            content: Text(chatState.errorMessage!),
            leading: const Icon(Icons.error_outline),
            actions: [
              TextButton(
                onPressed: onDismissError,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: messages.isEmpty && chatState.status == ChatStatus.idle
              ? _EmptyState(onSendSample: onSendSample)
              : _MessageList(
                  messages: messages,
                  chatState: chatState,
                  scrollController: scrollController,
                  showMarkdown: showMarkdown,
                ),
        ),
        ChatInput(
          onSend: onSend,
          isStreaming: chatState.status == ChatStatus.streaming,
          enabled: chatState.status == ChatStatus.idle ||
              chatState.status == ChatStatus.error,
          onStop: onStop,
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<Message> messages;
  final ChatState chatState;
  final ScrollController scrollController;
  final bool showMarkdown;

  const _MessageList({
    required this.messages,
    required this.chatState,
    required this.scrollController,
    this.showMarkdown = true,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isLastAssistant = index == messages.length - 1 &&
            msg.role == MessageRole.assistant &&
            chatState.status == ChatStatus.streaming;

        return MessageBubble(
          key: ValueKey(msg.id),
          message: msg,
          showMarkdown: showMarkdown,
          streamingOverride: isLastAssistant ? chatState.streamingText : null,
        );
      },
    );

    final content = isWideLayout(MediaQuery.sizeOf(context).width)
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: list,
            ),
          )
        : list;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: isWideLayout(MediaQuery.sizeOf(context).width),
      child: content,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String text) onSendSample;

  const _EmptyState({required this.onSendSample});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const samplePrompts = [
      'Tell me about yourself',
      'What can you help me with?',
      'Write a short poem',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_rounded,
              size: 64,
              color: theme.colorScheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Chat with your AI assistant',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: samplePrompts
                  .map(
                    (p) => ActionChip(
                      label: Text(p),
                      onPressed: () => onSendSample(p),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelPickerContent extends ConsumerWidget {
  const _ModelPickerContent();

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final registry = ref.read(providerRegistryProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<AiModel>>(
      future: registry.getAllModels(),
      builder: (context, snapshot) {
        final models = snapshot.data ?? [];

        final grouped = <String, List<AiModel>>{};
        for (final model in models) {
          grouped.putIfAbsent(model.providerId, () => []).add(model);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Model',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            if (models.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No models available'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in grouped.entries) ...[
                      _ProviderHeader(
                        providerId: entry.key,
                        label: _capitalize(entry.key),
                        registry: registry,
                        theme: theme,
                      ),
                      for (final model in entry.value)
                        ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.memory_outlined),
                          title: Text(model.displayName),
                          trailing:
                              model.qualifiedId == chatState.selectedModelId
                                  ? const Icon(Icons.check_circle_rounded)
                                  : null,
                          onTap: () async {
                            final activeConversationId =
                                ref.read(activeConversationIdProvider);
                            ref
                                .read(chatProvider.notifier)
                                .selectModel(model.qualifiedId);
                            if (activeConversationId != null) {
                              await ref
                                  .read(conversationsProvider.notifier)
                                  .setConversationModel(
                                    activeConversationId,
                                    model.qualifiedId,
                                  );
                            }
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  final String providerId;
  final String label;
  final ProviderRegistry registry;
  final ThemeData theme;

  const _ProviderHeader({
    required this.providerId,
    required this.label,
    required this.registry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = registry.getProvider(providerId);
    final isReady = provider?.currentStatus == ProviderStatus.ready;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReady ? Colors.green : theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
