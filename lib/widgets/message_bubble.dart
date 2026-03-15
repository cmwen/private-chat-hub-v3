import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/message.dart';
import '../utils/platform_utils.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showMarkdown;
  final String? streamingOverride;

  const MessageBubble({
    super.key,
    required this.message,
    this.showMarkdown = true,
    this.streamingOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    final text = streamingOverride ?? message.content;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = isWideLayout(screenWidth)
        ? desktopMessageMaxWidth
        : screenWidth * 0.82;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isUser
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                    bottomRight: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(context, text, isUser, theme),
                    if (!isUser &&
                        message.status == MessageStatus.sent &&
                        message.tokenUsage != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.token,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${message.tokenUsage!.total} tokens',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String text,
    bool isUser,
    ThemeData theme,
  ) {
    if (message.status == MessageStatus.sending && text.isEmpty) {
      return SizedBox(
        height: 20,
        width: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(delay: Duration.zero),
            _Dot(delay: const Duration(milliseconds: 200)),
            _Dot(delay: const Duration(milliseconds: 400)),
          ],
        ),
      );
    }

    if (message.status == MessageStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text.isEmpty ? 'Failed to send' : text,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (showMarkdown && !isUser && text.isNotEmpty) {
      return MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyMedium,
          code: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      );
    }

    return SelectableText(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isUser
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Duration delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6 + _animation.value * 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
