import 'package:flutter/material.dart';
import '../utils/model_id_utils.dart';

class ModelChip extends StatelessWidget {
  final String modelId;
  final VoidCallback? onTap;

  const ModelChip({super.key, required this.modelId, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = ModelIdUtils.extractModelId(modelId) ?? modelId;
    final provider = ModelIdUtils.extractProviderId(modelId) ?? '';
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: const Icon(Icons.memory_outlined, size: 16),
        label: Text('$provider: $name'),
        labelStyle: theme.textTheme.labelSmall,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
