import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../config/themes.dart';
import '../../../../../widgets/ct_section_label.dart';
import '../../../../../widgets/ct_spacing.dart';

/// Visual chrome variants for [RegionSectionHeader].
///
/// The civilian units panel (`UNIT10001`) keeps the catalog [CtSectionLabel]
/// bottom-border treatment ([RegionHeaderVariant.bottomBorder]); the military
/// (`UNIT20001`) and naval (`UNIT30001`) panels use the mockup left-accent-bar
/// treatment ([RegionHeaderVariant.leftBar]) per their HTML mockups
/// (`.region-label` / `.region-heading`, `border-left:3px var(--accent-dim)`).
enum RegionHeaderVariant { bottomBorder, leftBar }

/// Section title for a world region (Old World / New World) in units panels.
///
/// Implements `Refs #2866` S1–S3 region grouping. The default
/// [RegionHeaderVariant.bottomBorder] renders via [CtSectionLabel] (#2859). The
/// [RegionHeaderVariant.leftBar] variant matches the military/naval mockup
/// `.region-label` / `.region-heading` chrome — an upper-cased muted Cinzel
/// display label with a 3 dp [EditorialMonoclePalette.accentDim] left bar and
/// `6 × 3` dp inner padding (Refs #3514).
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

  @override
  Widget build(BuildContext context) {
    if (variant == RegionHeaderVariant.leftBar) {
      return _buildLeftBar(context);
    }
    return Padding(
      padding: const EdgeInsets.only(top: CtSpacing.m, bottom: 4),
      child: CtSectionLabel(label),
    );
  }

  Widget _buildLeftBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final TextStyle effectiveStyle = baseStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontFamily: editorialMonocleDisplayFontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.72,
    );
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
          child: Text(label.toUpperCase(), style: effectiveStyle),
        ),
      ),
    );
  }
}
