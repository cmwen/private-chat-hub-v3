import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../providers/conversation_provider.dart';
import '../utils/date_utils.dart' as date_utils;

class ConversationDrawer extends ConsumerWidget {
  const ConversationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final activeId = ref.watch(activeConversationIdProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.forum_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Private Chat Hub',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: FilledButton.icon(
              onPressed: () async {
                final conv = await ref
                    .read(conversationsProvider.notifier)
                    .createConversation();
                if (!context.mounted) return;
                ref.read(activeConversationIdProvider.notifier).state = conv.id;
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No conversations yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : _GroupedConversationList(
                    conversations: conversations,
                    activeId: activeId,
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
    );
  }
}

class _GroupedConversationList extends ConsumerWidget {
  final List<Conversation> conversations;
  final String? activeId;

  const _GroupedConversationList({
    required this.conversations,
    required this.activeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Groups in order: Today, Yesterday, Previous 7 Days, Older
    final grouped = date_utils.ConversationDateUtils.groupByDate(
      conversations,
      (c) => c.updatedAt,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final entry in grouped.entries) ...[
          _GroupHeader(label: entry.key),
          for (final conv in entry.value)
            _ConversationTile(
              conversation: conv,
              isActive: conv.id == activeId,
            ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;

  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final bool isActive;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListTile(
      selected: isActive,
      selectedTileColor: theme.colorScheme.secondaryContainer.withValues(
        alpha: 0.4,
      ),
      dense: true,
      leading: const Icon(Icons.chat_bubble_outline, size: 20),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.modelId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
      ),
      onTap: () {
        ref.read(activeConversationIdProvider.notifier).state = conversation.id;
        Navigator.of(context).pop();
      },
      onLongPress: () => _showActions(context, ref),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showRenameDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(conversationsProvider.notifier)
                    .archiveConversation(conversation.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(conversationsProvider.notifier)
                    .deleteConversation(conversation.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: conversation.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(conversationsProvider.notifier).renameConversation(
                    conversation.id, controller.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
