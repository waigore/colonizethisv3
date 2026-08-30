import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_gradients.dart';
import 'ct_resource_cell_format.dart';
import 'ct_resource_cell_trailing.dart';
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
///   * `delta == null` → delta glyphs omitted (no empty reserved slot after
///     the quantity — wide-layout inset parity, Refs #3999)
///
/// Trailing quantity (+ optional delta) use intrinsic width + [FittedBox]
/// scale-down so amounts stay visible at Available grid widths (Refs #3999).
/// The painted trailing cluster is right-pinned so its right inset matches
/// the leading icon inset ([CtSpacing.s]).
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

  /// Optional signed delta. See class dartdoc; `null` omits delta glyphs only.
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
  /// Returns `null` if the delta glyphs should not be painted.
  static String? formattedDeltaText(int? delta) =>
      ctResourceCellFormattedDeltaText(delta);

  /// Returns the colour token for the supplied [delta] per R10. Returns
  /// `null` if the delta glyphs should not be painted.
  static Color? deltaColor(int? delta) => ctResourceCellDeltaColor(delta);

  /// Renders an integer with thousands separators (`1_240` → `1,240`).
  static String formatQuantity(int value) => ctResourceCellFormatQuantity(value);

  /// Quantity [Text] key for visibility / panel-wide alignment tests (#3999).
  static const Key quantityTextKey = ValueKey<String>('ct_resource_cell_quantity');

  /// Delta [Text] key when a non-null [delta] is painted.
  static const Key deltaTextKey = ValueKey<String>('ct_resource_cell_delta');

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
          children: <Widget>[
            SizedBox(
              width: leadingIconSize,
              height: leadingIconSize,
              child: Center(child: iconBuilder(context)),
            ),
            const SizedBox(width: itemGap),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double budget = constraints.maxWidth;
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          name,
                          style: ctResourceCellNameStyle(context),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: budget),
                        child: ctResourceCellTrailingCluster(
                          context,
                          quantityText: formatQuantity(quantity),
                          deltaText: deltaText,
                          deltaTextColor: deltaTextColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
