import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/persona_document.dart';
import '../models/provider_model.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/llm_provider.dart';
import '../services/lm_studio_provider.dart';
import '../services/ollama_provider.dart';
import '../utils/platform_utils.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final historyDirectory = ref.watch(markdownHistoryDirectoryPathProvider);
    final personaDocument = ref.watch(personaDocumentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final listView = ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _SectionHeader(title: 'Chat'),
              SwitchListTile(
                title: const Text('Streaming'),
                subtitle: const Text('Show responses as they arrive'),
                value: settings.streamingEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setStreaming(v),
              ),
              SwitchListTile(
                title: const Text('Markdown Rendering'),
                subtitle: const Text('Format AI responses with markdown'),
                value: settings.markdownEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setMarkdown(v),
              ),
              _SectionHeader(title: 'Generation'),
              ListTile(
                title: const Text('Temperature'),
                subtitle: Slider(
                  value: settings.temperature,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  label: settings.temperature.toStringAsFixed(1),
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setTemperature(v),
                ),
                trailing: SizedBox(
                  width: 36,
                  child: Text(
                    settings.temperature.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _SectionHeader(title: 'Chat History'),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: const Text('When to save chat history'),
                subtitle: Text(
                  '${settings.chatHistorySaveMode.label}\n'
                  'Saved chats are stored as plain markdown (.md) files.',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChatHistorySaveModeDialog(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Plain markdown history directory'),
                subtitle: _MarkdownHistoryDirectorySubtitle(
                  historyDirectory: historyDirectory,
                  personaDocument: personaDocument,
                  isUsingDefaultDirectory:
                      settings.markdownHistoryDirectory.trim().isEmpty,
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMarkdownHistoryDirectoryDialog(context, ref),
              ),
              _SectionHeader(title: 'Providers'),
              _LmStudioSettingsTile(lmStudioBaseUrl: settings.lmStudioBaseUrl),
              _OllamaSettingsTile(ollamaBaseUrl: settings.ollamaBaseUrl),
              ListTile(
                leading: const Icon(Icons.smartphone_outlined),
                title: const Text('On-Device Models'),
                subtitle: const Text('Coming in a future update'),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
              ),
              _SectionHeader(title: 'About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Private Chat Hub'),
                subtitle: Text('v1.1.1'),
              ),
            ],
          );

          final body = isWideLayout(constraints.maxWidth)
              ? Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: desktopPageMaxWidth,
                    ),
                    child: listView,
                  ),
                )
              : listView;

          return Scrollbar(child: body);
        },
      ),
    );
  }

  Future<void> _showChatHistorySaveModeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentMode = ref.read(settingsProvider).chatHistorySaveMode;
    final selectedMode = await showDialog<ChatHistorySaveMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('When to save chat history'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ChatHistorySaveMode.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    mode == currentMode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(mode.label),
                  subtitle: Text(mode.description),
                  onTap: () => Navigator.of(dialogContext).pop(mode),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedMode == null || selectedMode == currentMode) {
      return;
    }

    await ref
        .read(settingsProvider.notifier)
        .setChatHistorySaveMode(selectedMode);
  }

  Future<void> _showMarkdownHistoryDirectoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settings = ref.read(settingsProvider);
    final effectiveDirectory =
        await ref.read(markdownHistoryDirectoryPathProvider.future);
    if (!context.mounted) {
      return;
    }

    final controller = TextEditingController(
      text: settings.markdownHistoryDirectory,
    );
    final selectedPath = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plain markdown history directory'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This directory is the authoritative plain markdown store. '
                'persona.md is read from the same folder, and SQLite only keeps a derived index/cache for performance.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Directory path',
                  hintText: effectiveDirectory,
                  helperText:
                      'Leave blank to use the app-managed default directory.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current effective directory:\n$effectiveDirectory',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (settings.markdownHistoryDirectory.trim().isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Use default'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (selectedPath == null) {
      return;
    }

    await ref
        .read(settingsProvider.notifier)
        .setMarkdownHistoryDirectory(selectedPath);
    ref.invalidate(markdownHistoryDirectoryPathProvider);
    ref.invalidate(personaDocumentProvider);
    ref.invalidate(newConversationDefaultsProvider);

    final updatedDirectory =
        await ref.read(markdownHistoryDirectoryPathProvider.future);
    await ref
        .read(conversationServiceProvider)
        .syncMarkdownHistoryIndex(force: true);
    await ref.read(conversationsProvider.notifier).refresh();

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Plain markdown history directory set to $updatedDirectory',
            ),
          ),
        );
    }
  }
}

class _MarkdownHistoryDirectorySubtitle extends StatelessWidget {
  final AsyncValue<String> historyDirectory;
  final AsyncValue<PersonaDocument?> personaDocument;
  final bool isUsingDefaultDirectory;

  const _MarkdownHistoryDirectorySubtitle({
    required this.historyDirectory,
    required this.personaDocument,
    required this.isUsingDefaultDirectory,
  });

  @override
  Widget build(BuildContext context) {
    final buffer = StringBuffer();
    historyDirectory.when(
      data: (path) {
        buffer.writeln(path);
        buffer.write(
          isUsingDefaultDirectory
              ? 'Using the app-managed default directory. '
              : 'Using a custom directory. ',
        );
      },
      error: (_, __) {
        buffer.write(
            'Unable to resolve the current markdown history directory. ');
      },
      loading: () {
        buffer.write('Resolving current markdown history directory... ');
      },
    );

    personaDocument.when(
      data: (persona) {
        if (persona == null) {
          buffer.write(
              'Place persona.md here to share default model and system prompt settings.');
        } else {
          buffer.write(
            'persona.md loaded for "${persona.name}". SQLite mirrors these markdown files as an index/cache.',
          );
        }
      },
      error: (_, __) {
        buffer.write('persona.md could not be read from this directory.');
      },
      loading: () {
        buffer.write('Checking persona.md...');
      },
    );

    return Text(buffer.toString().trim());
  }
}

class _OllamaSettingsTile extends ConsumerStatefulWidget {
  final String ollamaBaseUrl;

  const _OllamaSettingsTile({required this.ollamaBaseUrl});

  @override
  ConsumerState<_OllamaSettingsTile> createState() =>
      _OllamaSettingsTileState();
}

class _OllamaSettingsTileState extends ConsumerState<_OllamaSettingsTile> {
  @override
  Widget build(BuildContext context) {
    final ollamaStatus =
        ref.watch(ollamaProviderInstance.select((p) => p.currentStatus));

    return ListTile(
      leading: Icon(
        Icons.computer_outlined,
        color: _statusColor(context, ollamaStatus),
      ),
      title: const Text('Ollama (Self-Hosted)'),
      subtitle: Text(
        widget.ollamaBaseUrl.isEmpty
            ? 'Not configured — tap to add server URL'
            : widget.ollamaBaseUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(status: ollamaStatus),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showOllamaDialog(context),
    );
  }

  Color _statusColor(BuildContext context, ProviderStatus status) {
    final cs = Theme.of(context).colorScheme;
    if (status == ProviderStatus.ready) {
      return Colors.green;
    }
    if (status == ProviderStatus.offline || status == ProviderStatus.error) {
      return cs.error;
    }
    return cs.outline;
  }

  void _showOllamaDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.ollamaBaseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => _ProviderUrlDialog(
        title: 'Ollama Server',
        hintText: 'http://localhost:11434',
        helperText:
            'Use localhost for this computer or a LAN URL for another device.',
        controller: controller,
        testConnection: (url) async {
          if (url.trim().isEmpty) {
            return ProviderHealth(
              status: ProviderStatus.unconfigured,
              errorMessage: 'Enter a URL first',
            );
          }
          return OllamaProvider(baseUrl: url).checkHealth();
        },
        onSave: (url) async {
          await ref.read(settingsProvider.notifier).setOllamaBaseUrl(url);
          final ollamaInst = ref.read(ollamaProviderInstance);
          ollamaInst.updateBaseUrl(url);
          await ollamaInst.initialize();
        },
      ),
    );
  }
}

class _LmStudioSettingsTile extends ConsumerStatefulWidget {
  final String lmStudioBaseUrl;

  const _LmStudioSettingsTile({required this.lmStudioBaseUrl});

  @override
  ConsumerState<_LmStudioSettingsTile> createState() =>
      _LmStudioSettingsTileState();
}

class _LmStudioSettingsTileState extends ConsumerState<_LmStudioSettingsTile> {
  @override
  Widget build(BuildContext context) {
    final lmStudioStatus =
        ref.watch(lmStudioProviderInstance.select((p) => p.currentStatus));

    return ListTile(
      leading: Icon(
        Icons.terminal_outlined,
        color: _statusColor(context, lmStudioStatus),
      ),
      title: const Text('LM Studio (Local Server)'),
      subtitle: Text(
        widget.lmStudioBaseUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(status: lmStudioStatus),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showLmStudioDialog(context),
    );
  }

  Color _statusColor(BuildContext context, ProviderStatus status) {
    final cs = Theme.of(context).colorScheme;
    if (status == ProviderStatus.ready) {
      return Colors.green;
    }
    if (status == ProviderStatus.offline || status == ProviderStatus.error) {
      return cs.error;
    }
    return cs.outline;
  }

  void _showLmStudioDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.lmStudioBaseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => _ProviderUrlDialog(
        title: 'LM Studio Server',
        hintText: LmStudioProvider.defaultBaseUrl,
        helperText:
            'The default local server is http://localhost:1234/v1. If you omit /v1, it will be added automatically.',
        controller: controller,
        testConnection: (url) async {
          return LmStudioProvider(baseUrl: url).checkHealth();
        },
        onSave: (url) async {
          await ref.read(settingsProvider.notifier).setLmStudioBaseUrl(url);
          final lmStudioInst = ref.read(lmStudioProviderInstance);
          lmStudioInst.updateBaseUrl(url);
          await lmStudioInst.initialize();
        },
      ),
    );
  }
}

class _ProviderUrlDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String helperText;
  final TextEditingController controller;
  final Future<ProviderHealth> Function(String url) testConnection;
  final Future<void> Function(String url) onSave;

  const _ProviderUrlDialog({
    required this.title,
    required this.hintText,
    required this.helperText,
    required this.controller,
    required this.testConnection,
    required this.onSave,
  });

  @override
  State<_ProviderUrlDialog> createState() => _ProviderUrlDialogState();
}

class _ProviderUrlDialogState extends State<_ProviderUrlDialog> {
  bool _testing = false;
  String? _testResult;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: 'Base URL',
              hintText: widget.hintText,
              helperText: widget.helperText,
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: _testing
                    ? null
                    : () async {
                        setState(() {
                          _testing = true;
                          _testResult = null;
                        });
                        final url = widget.controller.text.trim();
                        if (url.isEmpty) {
                          setState(() {
                            _testing = false;
                            _testResult = 'Enter a URL first';
                          });
                          return;
                        }
                        final health = await widget.testConnection(url);
                        if (mounted) {
                          setState(() {
                            _testing = false;
                            _testResult = health.status == ProviderStatus.ready
                                ? '✓ Connected'
                                : '✗ ${health.errorMessage ?? health.status.name}';
                          });
                        }
                      },
                child: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test'),
              ),
              if (_testResult != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testResult!.startsWith('✓')
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final url = widget.controller.text.trim();
            await widget.onSave(url);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final ProviderStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == ProviderStatus.ready) {
      color = Colors.green;
    } else if (status == ProviderStatus.offline ||
        status == ProviderStatus.error) {
      color = Theme.of(context).colorScheme.error;
    } else {
      color = Theme.of(context).colorScheme.outline;
    }
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
