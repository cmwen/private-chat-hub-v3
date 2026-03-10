import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import '../models/provider_model.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/provider_registry.dart';
import '../widgets/chat_input.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_chip.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

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
      final settings = ref.read(settingsProvider);
      final conv =
          await ref.read(conversationsProvider.notifier).createConversation(
                title: 'New Chat',
                modelId: settings.defaultModelId,
              );
      if (mounted) {
        ref.read(activeConversationIdProvider.notifier).state = conv.id;
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final activeId = ref.watch(activeConversationIdProvider);
    final messages =
        activeId != null ? ref.watch(messagesProvider(activeId)) : <Message>[];

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
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: () async {
              final settings = ref.read(settingsProvider);
              final conv = await ref
                  .read(conversationsProvider.notifier)
                  .createConversation(
                    title: 'New Chat',
                    modelId: settings.defaultModelId,
                  );
              if (mounted) {
                ref.read(activeConversationIdProvider.notifier).state = conv.id;
              }
            },
          ),
        ],
      ),
      drawer: const ConversationDrawer(),
      body: Column(
        children: [
          if (chatState.status == ChatStatus.error &&
              chatState.errorMessage != null)
            MaterialBanner(
              content: Text(chatState.errorMessage!),
              leading: const Icon(Icons.error_outline),
              actions: [
                TextButton(
                  onPressed: () => ref.read(chatProvider.notifier).clearError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: messages.isEmpty && chatState.status == ChatStatus.idle
                ? _EmptyState(onSendSample: (text) async {
                    final convId = await _ensureConversation();
                    if (mounted) {
                      ref.read(chatProvider.notifier).sendMessage(text, convId);
                    }
                  })
                : _MessageList(
                    messages: messages,
                    chatState: chatState,
                    scrollController: _scrollController,
                    showMarkdown: ref.watch(settingsProvider).markdownEnabled,
                  ),
          ),
          ChatInput(
            onSend: (text) async {
              final convId = await _ensureConversation();
              if (mounted) {
                ref.read(chatProvider.notifier).sendMessage(text, convId);
              }
            },
            isStreaming: chatState.status == ChatStatus.streaming,
            enabled: chatState.status == ChatStatus.idle ||
                chatState.status == ChatStatus.error,
            onStop: () => ref.read(chatProvider.notifier).stopGeneration(),
          ),
        ],
      ),
    );
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => const _ModelPickerSheet(),
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
    return ListView.builder(
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
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function(String text) onSendSample;

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

class _ModelPickerSheet extends ConsumerWidget {
  const _ModelPickerSheet();

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

        // Group models by providerId, preserving insertion order.
        final grouped = <String, List<AiModel>>{};
        for (final model in models) {
          grouped.putIfAbsent(model.providerId, () => []).add(model);
        }

        return SafeArea(
          child: Column(
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
                        // Provider header row
                        _ProviderHeader(
                          providerId: entry.key,
                          label: _capitalize(entry.key),
                          registry: registry,
                          theme: theme,
                        ),
                        // Model tiles for this provider
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
                            onTap: () {
                              ref
                                  .read(chatProvider.notifier)
                                  .selectModel(model.qualifiedId);
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Header row shown once per provider group in [_ModelPickerSheet].
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
    // Use a representative qualified ID to look up provider status.
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
