// Standing-chip cluster + hover row chrome for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster and
// § Per-faction row → Row chrome.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'diplomacy_panel_chrome_colors.dart';
import 'diplomacy_panel_rows.dart';

/// A single diplomatic standing chip rendered in the
/// [DiplomacyStandingChipCluster]. Mirrors the WAR/PEACE/ALLIANCE badge chrome
/// (mono 9 sp, 1 × 5 dp padding, square 1 dp corners) so the cluster reads as
/// a row of compact treaty/economic markers. SPEC/ui/diplomacy-panel.md
/// § Diplomatic standing chip cluster (Refs #3753 R12).
class DiplomacyStandingChip extends StatelessWidget {
  const DiplomacyStandingChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          fontSize: 9,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Compact chip cluster listing every active diplomatic overture/treaty/
/// economic state for a faction row (Refs #3753 R12 / S13). Rendered below the
/// relation line on the panel row and inside the diplomacy detail screen's
/// `CURRENT RELATION` card, replacing the prior single inline overture-stage
/// clause. Renders nothing when no standing chip applies.
///
/// Chip families reuse the canonical editorial-monocle badge overlay tokens
/// (no new palette tokens, no Material chrome) per
/// SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster:
///
/// - Overture/treaty/colony chips → accent overlay (alliance-badge chrome).
/// - Boycott chips → warm-red overlay (WAR relation-state chrome).
/// - Overseas-holdings chip → cool-green overlay (PEACE relation-state chrome).
class DiplomacyStandingChipCluster extends StatelessWidget {
  const DiplomacyStandingChipCluster({super.key, required this.chips});

  final DiplomaticStandingChips chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<Widget> children = <Widget>[];
    for (final String label in chips.treatyLabels) {
      children.add(
        DiplomacyStandingChip(
          label: label,
          background: diplomacyPanelAllianceBadgeBackground,
          foreground: EditorialMonoclePalette.accent,
        ),
      );
    }
    for (final String name in chips.boycottVsNames) {
      children.add(
        DiplomacyStandingChip(
          label: '$kDiplomacyChipBoycottVsPrefix$name',
          background: diplomacyPanelWarBadgeBackground,
          foreground: EditorialMonoclePalette.danger,
        ),
      );
    }
    for (final String name in chips.boycottedByNames) {
      children.add(
        DiplomacyStandingChip(
          label: '$kDiplomacyChipBoycottedByPrefix$name',
          background: diplomacyPanelWarBadgeBackground,
          foreground: EditorialMonoclePalette.danger,
        ),
      );
    }
    if (chips.overseasTileCount > 0) {
      children.add(
        DiplomacyStandingChip(
          label: '$kDiplomacyChipOverseasPrefix${chips.overseasTileCount} '
              '\u00b7 ${chips.overseasSharePercent}%',
          background: diplomacyPanelPeaceBadgeBackground,
          foreground: EditorialMonoclePalette.success,
        ),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CtSpacing.s,
      runSpacing: CtSpacing.xs,
      children: children,
    );
  }
}

/// Hover-aware faction row chrome per SPEC/ui/diplomacy-panel.md
/// § Per-faction row → Row chrome. Paints a vertical
/// `linear-gradient(180deg, --bg-deep, --surface)` background, a 1 px
/// `--border` outline, and animates the outline to `--accent-dim` while
/// pointer-hovered. The 4 px outer bottom margin matches `.faction-row`
/// in [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html).
class DiplomacyRowChrome extends StatefulWidget {
  const DiplomacyRowChrome({required this.child});

  final Widget child;

  /// Outer bottom gap between consecutive faction rows.
  static const double rowGap = 4;

  /// Token-resolved 180° gradient used by the row body.
  static LinearGradient get rowGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );

  @override
  State<DiplomacyRowChrome> createState() => _DiplomacyRowChromeState();
}

class _DiplomacyRowChromeState extends State<DiplomacyRowChrome> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _hovered
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: DiplomacyRowChrome.rowGap),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            gradient: DiplomacyRowChrome.rowGradient,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
