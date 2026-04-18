import 'package:flutter/material.dart';

/// Pixel-art friendly toggle chip (non-Material).
class CtChoiceChip extends StatelessWidget {
  const CtChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = selected
        ? colorScheme.primary.withValues(alpha: 0.25)
        : colorScheme.surface.withValues(alpha: 0.5);
    final border = selected ? colorScheme.primary : colorScheme.outline;

    return InkWell(
      onTap: () => onSelected(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall ??
              const TextStyle(fontSize: 12),
          child: label,
        ),
      ),
    );
  }
}

