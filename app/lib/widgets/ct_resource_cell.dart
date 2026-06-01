import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';
import 'ct_gradients.dart';
import 'ct_spacing.dart';

/// Compact icon + name + quantity (+ optional signed delta) row for the dark
/// editorial-monocle theme.
///
/// Implements `Refs #2859` R10 + § *CtResourceCell* in
/// `SPEC/ui/pixel-art-ui-catalog.md`. The cell mirrors the
/// `.resource-cell` block in `SPEC/ui/mockups/GAME20001-production-panel.html`:
///
/// * a leading 20x20 pixel-icon slot whose painter is supplied by the
///   consumer via [iconBuilder] (typically a `ResourceIcon`);
/// * a flexible name column rendered with the dark-theme body font, overflowing
///   with ellipsis when constrained;
/// * a trailing monospace quantity coloured `--accent-dim`;
/// * an optional trailing monospace delta whose colour is driven entirely by
///   the delta's sign per R10:
///   * `delta > 0`  → `+N`, colour `--success`
///   * `delta < 0`  → `-N` (numeric sign), colour `--danger`
///   * `delta == 0` → `0`, colour `--muted`
///   * `delta == null` → delta region is not laid out
///
/// All colors resolve from [EditorialMonoclePalette] tokens (issue #2858);
/// no hard-coded hex literals.
class CtResourceCell extends StatelessWidget {
  const CtResourceCell({
    super.key,
    required this.iconBuilder,
    required this.name,
    required this.quantity,
    this.delta,
    this.padding = const EdgeInsets.symmetric(horizontal: CtSpacing.s, vertical: 4),
  });

  /// Consumer-supplied painter for the leading icon. Returned widget is
  /// centered inside a [leadingIconSize] x [leadingIconSize] slot. Pass a
  /// `ResourceIcon` from `resource_icon.dart` for canonical commodity icons.
  final WidgetBuilder iconBuilder;

  /// Display label rendered in the flexible middle column.
  final String name;

  /// Current quantity. Rendered as a thousands-separated number in the
  /// dark-theme monospace slot.
  final int quantity;

  /// Optional signed delta. See class dartdoc for colour and prefix rules.
  /// `null` omits the delta region entirely.
  final int? delta;

  /// Outer padding for the cell (`4px` vertical / `CtSpacing.s` (6px)
  /// horizontal by default, matching the mockup
  /// `.resource-cell { padding: 4px 6px }`). The vertical `4` is
  /// intentionally out-of-scale per
  /// `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* (the scale
  /// skips `4`; mockup-pinned per-component override).
  final EdgeInsetsGeometry padding;

  /// Leading icon slot size (`20x20 px`), matching the mockup.
  static const double leadingIconSize = 20;

  /// Horizontal gap between adjacent cell elements (`gap: 5px` in the mockup).
  static const double itemGap = 5;

  /// Horizontal gap between the quantity and an optional delta cell
  /// (`.r-delta { margin-left: 2px }` in the mockup).
  static const double quantityToDeltaGap = 2;

  /// Returns the formatted delta string for the supplied [delta] per R10.
  /// Returns `null` if the delta region should not be laid out.
  static String? formattedDeltaText(int? delta) {
    if (delta == null) return null;
    if (delta > 0) return '+$delta';
    return '$delta';
  }

  /// Returns the colour token for the supplied [delta] per R10. Returns
  /// `null` if the delta region should not be laid out.
  static Color? deltaColor(int? delta) {
    if (delta == null) return null;
    if (delta > 0) return EditorialMonoclePalette.success;
    if (delta < 0) return EditorialMonoclePalette.danger;
    return EditorialMonoclePalette.muted;
  }

  /// Renders an integer with thousands separators (`1_240` → `1,240`).
  /// Kept inline so the widget does not pull in `intl` for a single use.
  /// Also reused by the production-panel e2e text-mirror fixture
  /// (`production_panel_e2e_expected_lines.dart`) so it stays stable across
  /// callers.
  static String formatQuantity(int value) {
    final String raw = value.abs().toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int posFromRight = raw.length - i;
      if (i > 0 && posFromRight % 3 == 0) out.write(',');
      out.write(raw[i]);
    }
    if (value < 0) return '-${out.toString()}';
    return out.toString();
  }

  TextStyle _nameStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return base.copyWith(color: EditorialMonoclePalette.fg);
  }

  TextStyle _monoStyle(BuildContext context, {required Color color}) {
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    return base.copyWith(
      color: color,
      fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? deltaText = formattedDeltaText(delta);
    final Color? deltaTextColor = deltaColor(delta);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.rowGradient,
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: leadingIconSize,
              height: leadingIconSize,
              child: Center(child: iconBuilder(context)),
            ),
            const SizedBox(width: itemGap),
            Expanded(
              child: Text(
                name,
                style: _nameStyle(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: itemGap),
            Text(
              formatQuantity(quantity),
              style: _monoStyle(
                context,
                color: EditorialMonoclePalette.accentDim,
              ),
            ),
            if (deltaText != null) ...<Widget>[
              const SizedBox(width: quantityToDeltaGap),
              Text(
                deltaText,
                style: _monoStyle(context, color: deltaTextColor!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
