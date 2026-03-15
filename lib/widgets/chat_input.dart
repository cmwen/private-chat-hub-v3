import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/platform_utils.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text) onSend;
  final bool enabled;
  final VoidCallback? onStop;
  final bool isStreaming;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.onStop,
    this.isStreaming = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text);
    _focusNode.requestFocus();
  }

  void _sendIfPossible() {
    if (_hasText && widget.enabled && !widget.isStreaming) {
      _send();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.enter, control: true):
          _sendIfPossible,
      const SingleActivator(LogicalKeyboardKey.enter, meta: true):
          _sendIfPossible,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: bindings,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled && !widget.isStreaming,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.isStreaming
                        ? 'Waiting for response…'
                        : 'Message…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isStreaming)
              IconButton.filled(
                onPressed: widget.onStop,
                icon: const Icon(Icons.stop_rounded),
                tooltip: 'Stop',
              )
            else
              IconButton.filled(
                onPressed: (_hasText && widget.enabled) ? _send : null,
                icon: const Icon(Icons.send_rounded),
                tooltip: isDesktopPlatform
                    ? 'Send (Ctrl+Enter or Cmd+Enter)'
                    : 'Send',
              ),
          ],
        ),
      ),
    );
  }
}
