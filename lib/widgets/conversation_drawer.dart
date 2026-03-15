import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../providers/conversation_provider.dart';
import '../utils/date_utils.dart' as date_utils;

class ConversationDrawer extends ConsumerWidget {
  final bool embedded;

  const ConversationDrawer({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final activeId = ref.watch(activeConversationIdProvider);
    final theme = Theme.of(context);
    final content = SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton.icon(
              onPressed: () async {
                final conv = await ref
                    .read(conversationsProvider.notifier)
                    .createConversation();
                if (!context.mounted) return;
                ref.read(activeConversationIdProvider.notifier).state = conv.id;
                if (!embedded) {
                  Navigator.of(context).pop();
                }
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
                : Scrollbar(
                    child: _GroupedConversationList(
                      conversations: conversations,
                      activeId: activeId,
                      closeOnSelect: !embedded,
                    ),
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              if (!embedded) {
                Navigator.of(context).pop();
              }
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
    );

    if (embedded) {
      return Material(
        color: theme.colorScheme.surfaceContainerLow,
        child: content,
      );
    }

    return Drawer(child: content);
  }
}

class _GroupedConversationList extends ConsumerWidget {
  final List<Conversation> conversations;
  final String? activeId;
  final bool closeOnSelect;

  const _GroupedConversationList({
    required this.conversations,
    required this.activeId,
    required this.closeOnSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              closeOnSelect: closeOnSelect,
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
  final bool closeOnSelect;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.closeOnSelect,
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
      trailing: PopupMenuButton<_ConversationAction>(
        tooltip: 'Conversation actions',
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _ConversationAction.rename,
            child: _ConversationActionRow(
              icon: Icons.edit_outlined,
              label: 'Rename',
            ),
          ),
          const PopupMenuItem(
            value: _ConversationAction.archive,
            child: _ConversationActionRow(
              icon: Icons.archive_outlined,
              label: 'Archive',
            ),
          ),
          PopupMenuItem(
            value: _ConversationAction.delete,
            child: _ConversationActionRow(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      onTap: () {
        ref.read(activeConversationIdProvider.notifier).state = conversation.id;
        if (closeOnSelect) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    _ConversationAction action,
  ) {
    switch (action) {
      case _ConversationAction.rename:
        _showRenameDialog(context, ref);
        return;
      case _ConversationAction.archive:
        ref
            .read(conversationsProvider.notifier)
            .archiveConversation(conversation.id);
        return;
      case _ConversationAction.delete:
        ref
            .read(conversationsProvider.notifier)
            .deleteConversation(conversation.id);
        return;
    }
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

class _ConversationActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ConversationActionRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Text(label, style: color != null ? TextStyle(color: color) : null),
      ],
    );
  }
}

enum _ConversationAction { rename, archive, delete }
