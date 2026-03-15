import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_model.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ollama_provider.dart';
import '../utils/platform_utils.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

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
              _SectionHeader(title: 'Providers'),
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
                subtitle: Text('v1.0.0 – Phase 1'),
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
}

class _OllamaSettingsTile extends ConsumerStatefulWidget {
  final String ollamaBaseUrl;

  const _OllamaSettingsTile({required this.ollamaBaseUrl});

  @override
  ConsumerState<_OllamaSettingsTile> createState() =>
      _OllamaSettingsTileState();
}

class _OllamaSettingsTileState extends ConsumerState<_OllamaSettingsTile> {
  bool _testing = false;
  String? _testResult;

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
    if (status == ProviderStatus.ready) return Colors.green;
    if (status == ProviderStatus.offline || status == ProviderStatus.error) {
      return cs.error;
    }
    return cs.outline;
  }

  void _showOllamaDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.ollamaBaseUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => _OllamaDialog(
        controller: controller,
        testing: _testing,
        testResult: _testResult,
        onTest: () async {
          setState(() {
            _testing = true;
            _testResult = null;
          });
          final url = controller.text.trim();
          if (url.isEmpty) {
            setState(() {
              _testing = false;
              _testResult = 'Enter a URL first';
            });
            return;
          }
          final tempProvider = OllamaProvider(baseUrl: url);
          final health = await tempProvider.checkHealth();
          if (mounted) {
            setState(() {
              _testing = false;
              _testResult = health.status == ProviderStatus.ready
                  ? '✓ Connected'
                  : '✗ ${health.errorMessage ?? health.status.name}';
            });
          }
        },
        onSave: (url) async {
          await ref.read(settingsProvider.notifier).setOllamaBaseUrl(url);
          final ollamaInst = ref.read(ollamaProviderInstance);
          ollamaInst.updateBaseUrl(url);
          await ollamaInst.initialize();
          setState(() {
            _testing = false;
            _testResult = null;
          });
        },
      ),
    );
  }
}

class _OllamaDialog extends StatefulWidget {
  final TextEditingController controller;
  final bool testing;
  final String? testResult;
  final VoidCallback onTest;
  final Future<void> Function(String url) onSave;

  const _OllamaDialog({
    required this.controller,
    required this.testing,
    required this.testResult,
    required this.onTest,
    required this.onSave,
  });

  @override
  State<_OllamaDialog> createState() => _OllamaDialogState();
}

class _OllamaDialogState extends State<_OllamaDialog> {
  late bool _testing;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _testing = widget.testing;
    _testResult = widget.testResult;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ollama Server'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'http://localhost:11434',
              helperText:
                  'Use localhost for this computer or a LAN URL for another device.',
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
                        final tempProvider = OllamaProvider(baseUrl: url);
                        final health = await tempProvider.checkHealth();
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
            if (context.mounted) Navigator.of(context).pop();
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
