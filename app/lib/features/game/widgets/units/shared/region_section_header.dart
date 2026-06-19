import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../config/themes.dart';
import '../../../../../widgets/ct_section_label.dart';
import '../../../../../widgets/ct_spacing.dart';

/// Visual chrome variants for [RegionSectionHeader].
///
/// The military (`UNIT20001`) and naval (`UNIT30001`) panels use the mockup
/// left-accent-bar treatment ([RegionHeaderVariant.leftBar]) per their HTML
/// mockups (`.region-label` / `.region-heading`,
/// `border-left:3px var(--accent-dim)`). The civilian units panel
/// (`UNIT10001`) uses the mockup `.region-heading` bottom-border treatment
/// ([RegionHeaderVariant.bottomBorderMuted]) — an upper-cased muted display
/// label with a 1 dp [EditorialMonoclePalette.border] (`var(--border)`) bottom
/// border. [RegionHeaderVariant.bottomBorder] is the legacy catalog
/// [CtSectionLabel] treatment (brass-tinted `--accent-dim` bottom border),
/// retained for non-units callers.
enum RegionHeaderVariant { bottomBorder, bottomBorderMuted, leftBar }

/// Section title for a world region (Old World / New World) in units panels.
///
/// Implements `Refs #2866` S1–S3 region grouping. The default
/// [RegionHeaderVariant.bottomBorder] renders via [CtSectionLabel] (#2859). The
/// [RegionHeaderVariant.leftBar] variant matches the military/naval mockup
/// `.region-label` / `.region-heading` chrome — an upper-cased muted Cinzel
/// display label with a 3 dp [EditorialMonoclePalette.accentDim] left bar and
/// `6 × 3` dp inner padding. The [RegionHeaderVariant.bottomBorderMuted]
/// variant matches the civilian mockup `.region-heading` chrome — the same
/// upper-cased muted display label over a 1 dp [EditorialMonoclePalette.border]
/// (`var(--border)`) bottom border (Refs #3514).
class RegionSectionHeader extends StatelessWidget {
  const RegionSectionHeader({
    super.key,
    required this.label,
    this.variant = RegionHeaderVariant.bottomBorder,
  });

  final String label;

  /// Visual chrome treatment; see [RegionHeaderVariant].
  final RegionHeaderVariant variant;

  /// Left bar thickness for [RegionHeaderVariant.leftBar] (mockup `3px`).
  static const double leftBarWidth = 3;

  /// Bottom border thickness for [RegionHeaderVariant.bottomBorderMuted]
  /// (mockup `.region-heading` `border-bottom:1px var(--border)`).
  static const double bottomBorderWidth = 1;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case RegionHeaderVariant.leftBar:
        return _buildLeftBar(context);
      case RegionHeaderVariant.bottomBorderMuted:
        return _buildBottomBorderMuted(context);
      case RegionHeaderVariant.bottomBorder:
        return Padding(
          padding: const EdgeInsets.only(top: CtSpacing.m, bottom: 4),
          child: CtSectionLabel(label),
        );
    }
  }

  /// Upper-cased muted Cinzel display label shared by the mockup-faithful
  /// variants (`.region-label` / `.region-heading`).
  TextStyle _mockupLabelStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return baseStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontFamily: editorialMonocleDisplayFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.72,
    );
  }

  Widget _buildLeftBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: CtSpacing.m, bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: EditorialMonoclePalette.accentDim,
              width: leftBarWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CtSpacing.s,
            vertical: 3,
          ),
          child: Text(label.toUpperCase(), style: _mockupLabelStyle(context)),
        ),
      ),
    );
  }

  Widget _buildBottomBorderMuted(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: CtSpacing.m, bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.border,
              width: bottomBorderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(label.toUpperCase(), style: _mockupLabelStyle(context)),
        ),
      ),
    );
  }
}
