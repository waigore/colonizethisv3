// Section heading + faction type badge chrome for DiplomacyPanel.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/routes.dart';
import '../../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_radius.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/relation_meter.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_rows_models.dart';
import 'fnv1a_hash_constants.dart';
import 'relative_power_line.dart';
// Section heading + faction type badge chrome for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Section headings and § Per-faction row → Type
// badge colors.


/// Translucent overlay used as the WAR-state badge background, derived
/// from the `--danger` hue at lightness 0.40, chroma 0.06, hue 20, alpha
/// 0.40. SPEC/ui/diplomacy-panel.md § Relation state badge cites the
/// mockup token `oklch(40% 0.06 20 / 0.4)` directly; this constant
/// computes the same OKLCH sRGB approximation through [oklchToColor].
final Color diplomacyWarBadgeBackground = oklchToColor(
  const OklchToken(0.40, 0.06, 20),
).withValues(alpha: 0.4);

/// Translucent overlay used as the PEACE-state badge background, derived
/// from the `--success` hue at lightness 0.40, chroma 0.06, hue 150,
/// alpha 0.20. SPEC/ui/diplomacy-panel.md § Relation state badge cites
/// the mockup token `oklch(40% 0.06 150 / 0.2)`.
final Color diplomacyPeaceBadgeBackground = oklchToColor(
  const OklchToken(0.40, 0.06, 150),
).withValues(alpha: 0.2);

/// Section heading for a diplomacy faction group (Great Powers / Minor
/// Nations / Tribes).
///
/// SPEC/ui/diplomacy-panel.md § Section headings: display font, `--accent`
/// text color, 2 px `--accent-dim` bottom border per
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.section-head`.
class DiplomacySectionHeader extends StatelessWidget {
  const DiplomacySectionHeader({required this.title, this.isFirst = false});

  final String title;

  /// Whether this is the first section heading rendered in the list under the
  /// active mode-bar filter. SPEC/ui/diplomacy-panel.md § Section headings
  /// (first-heading top rhythm, Refs #3621): the first heading drops its top
  /// gap to `0` (mockup `.section-head:first-child { margin-top: 0 }`) while
  /// every subsequent heading keeps the `CtSpacing.l` leading gap.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final TextStyle headingStyle = baseStyle.copyWith(
      color: EditorialMonoclePalette.accent,
      fontFamily: editorialMonocleDisplayFontFamily,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : CtSpacing.l,
        bottom: CtSpacing.m,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.accentDim,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: CtSpacing.s),
          child: Text(title, style: headingStyle),
        ),
      ),
    );
  }
}

/// Faction type badge (GP / Minor / Tribe) for diplomacy rows.
///
/// SPEC/ui/diplomacy-panel.md § Per-faction row → Type badge colors:
/// - GP: `--accent-dim` background, `--bg-deep` foreground.
/// - Minor: `--muted` background, `--bg-deep` foreground.
/// - Tribe: outlined — transparent background, `--muted` border + foreground.
///
/// Matches [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.f-badge` chrome (mono font, tight letter-spacing, square `1px`
/// border-radius). All colors resolve from the canonical editorial-monocle
/// palette — no hardcoded Material chrome.
class DiplomacyFactionKindBadge extends StatelessWidget {
  const DiplomacyFactionKindBadge({required this.kind});

  final FactionKind kind;

  @override
  Widget build(BuildContext context) {
    final ({String label, Color? background, Color? border, Color foreground})
    spec = switch (kind) {
      FactionKind.greatPower => (
        label: 'GP',
        background: EditorialMonoclePalette.accentDim,
        border: null,
        foreground: EditorialMonoclePalette.bgDeep,
      ),
      FactionKind.minor => (
        label: 'Minor',
        background: EditorialMonoclePalette.muted,
        border: null,
        foreground: EditorialMonoclePalette.bgDeep,
      ),
      FactionKind.tribe => (
        label: 'Tribe',
        background: null,
        border: EditorialMonoclePalette.muted,
        foreground: EditorialMonoclePalette.muted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CtSpacing.s,
        vertical: CtSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: spec.background,
        border: spec.border == null
            ? null
            : Border.all(color: spec.border!, width: 1),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.foreground,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}
