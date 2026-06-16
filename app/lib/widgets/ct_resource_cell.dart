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
/// * a flexible name column rendered with the dark-theme body font that takes
///   all residual width (so the trailing cluster is pinned to the card's right
///   edge), overflowing with ellipsis only as a last-resort fallback;
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

  /// Name + quantity font size in logical px. Matches the mockup
  /// `.resource-cell` `font-size: clamp(9px, 1.3vw, 10px)` ceiling so the
  /// compact cells fit canonical commodity / worker names in full within the
  /// 3-column / 2-column Available grid (Refs #2862 S9 / C9).
  static const double nameFontSize = 10;

  /// Quantity font size in logical px. Shares the mockup `.r-qty`
  /// `clamp(9px, 1.3vw, 10px)` ceiling with [nameFontSize].
  static const double quantityFontSize = 10;

  /// Delta font size in logical px. Matches the mockup `.r-delta`
  /// `font-size: clamp(8px, 1.1vw, 9px)` ceiling — one step smaller than the
  /// quantity so the trailing cluster stays at minimal intrinsic width and a
  /// name that fits without a delta still fits with one (Refs #2862 S9 / C10).
  static const double deltaFontSize = 9;

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
    return base.copyWith(
      color: EditorialMonoclePalette.fg,
      fontSize: nameFontSize,
    );
  }

  TextStyle _monoStyle(
    BuildContext context, {
    required Color color,
    required double fontSize,
  }) {
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    return base.copyWith(
      color: color,
      fontSize: fontSize,
      fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  /// A single trailing monospace [Text] (ellipsizing, one line). Kept as a
  /// distinct widget per value so the quantity and delta remain individually
  /// findable / colour-assertable, while [_trailingCluster] composes them.
  Widget _monoText(
    BuildContext context, {
    required String text,
    required Color color,
    required double fontSize,
  }) {
    return Text(
      text,
      style: _monoStyle(context, color: color, fontSize: fontSize),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Outer-[Row] flex factor of the [Expanded] name column relative to the
  /// trailing quantity/delta cluster ([trailingFlex]). The name claims the
  /// large majority of residual width so canonical commodity / worker names
  /// render in full at normal grid widths instead of being squeezed into
  /// ellipsis by an equal-flex trailing cluster (issue #3485 regression).
  static const int nameFlex = 3;

  /// Outer-[Row] flex factor of the trailing quantity/delta cluster. The
  /// cluster's slot is the **last** flex child, so its right edge coincides
  /// with the card's inner-right edge; the cluster's content is right-aligned
  /// within the slot (see [_trailingCluster]) so the amount is pinned to that
  /// edge. The small flex (vs [nameFlex]) keeps the slot wide enough to show
  /// the quantity + optional delta in full at normal widths while still
  /// collapsing — and letting the values ellipsize — at pathologically narrow
  /// widths instead of overflowing.
  static const int trailingFlex = 1;

  /// Builds the trailing quantity + optional delta as the **last** flex child
  /// of the outer [Row] (see [build]). The cluster slot's right edge coincides
  /// with the card's inner-right edge, and the cluster's content is
  /// right-aligned within the slot via [Alignment.centerRight], so the quantity
  /// (and, when present, the trailing `+N` / `-N` delta) is pinned hard against
  /// the card's right edge whether or not a delta is shown (issue #3485). The
  /// optional delta sits immediately to the right of the quantity per the
  /// mockup `.resource-cell` order. Inside the cluster each value is a loose
  /// [Flexible] with `maxLines: 1` + ellipsis so it shrinks as a defensive
  /// last-resort fallback at pathologically narrow widths instead of
  /// overflowing; in normal usage neither value ellipsizes (Refs #2862 S9 / C10,
  /// #3485).
  Widget _trailingCluster(
    BuildContext context, {
    required String quantityText,
    required String? deltaText,
    required Color? deltaTextColor,
  }) {
    return Flexible(
      fit: FlexFit.loose,
      flex: trailingFlex,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              fit: FlexFit.loose,
              child: _monoText(
                context,
                text: quantityText,
                color: EditorialMonoclePalette.accentDim,
                fontSize: quantityFontSize,
              ),
            ),
            if (deltaText != null) ...<Widget>[
              const SizedBox(width: quantityToDeltaGap),
              Flexible(
                fit: FlexFit.loose,
                child: _monoText(
                  context,
                  text: deltaText,
                  color: deltaTextColor!,
                  fontSize: deltaFontSize,
                ),
              ),
            ],
          ],
        ),
      ),
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
              flex: nameFlex,
              child: Text(
                name,
                style: _nameStyle(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: itemGap),
            _trailingCluster(
              context,
              quantityText: formatQuantity(quantity),
              deltaText: deltaText,
              deltaTextColor: deltaTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
