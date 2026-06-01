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

  /// Tap handler. When `null` the chip renders in a disabled state
  /// (muted colours, no tap callback). Mirrors the disabled pattern
  /// used by Material `FilterChip` / `ChoiceChip` so callers can gate
  /// chip availability without wrapping the widget in an
  /// `IgnorePointer` / `Opacity` pair.
  final ValueChanged<bool>? onSelected;

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
    final bool disabled = onSelected == null;
    final Color bg;
    final Color border;
    if (disabled) {
      bg = colorScheme.surface.withValues(alpha: 0.25);
      border = colorScheme.outline.withValues(alpha: 0.4);
    } else if (selected) {
      bg = colorScheme.primary.withValues(alpha: 0.25);
      border = colorScheme.primary;
    } else {
      bg = colorScheme.surface.withValues(alpha: 0.5);
      border = colorScheme.outline;
    }
    final ValueChanged<bool>? handler = onSelected;
    final Color labelColor = disabled
        ? colorScheme.onSurface.withValues(alpha: 0.4)
        : (theme.textTheme.bodySmall?.color ?? colorScheme.onSurface);
    final TextStyle labelStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
      color: labelColor,
    );
    return InkWell(
      onTap: handler == null ? null : () => handler(!selected),
      child: Container(
        padding: defaultPadding,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1),
        ),
        child: DefaultTextStyle(
          style: labelStyle,
          child: label,
        ),
      ),
    );
  }
}

