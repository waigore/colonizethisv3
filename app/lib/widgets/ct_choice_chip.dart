import 'package:flutter/material.dart';

import 'ct_spacing.dart';

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

  /// Default chip inner padding. Horizontal `CtSpacing.m` (8 px) per
  /// `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens*; vertical `4`
  /// is intentionally out-of-scale (the scale skips `4`; mockup-pinned
  /// per-component override).
  @visibleForTesting
  static const EdgeInsetsGeometry defaultPadding = EdgeInsets.symmetric(
    horizontal: CtSpacing.m,
    vertical: 4,
  );

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
        padding: defaultPadding,
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

