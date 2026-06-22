// Shared "Relative power: +N% · Tier" line for Great Power diplomacy surfaces
// (diplomacy panel rows + diplomacy detail screen).
// SPEC/ui/diplomacy-panel.md § Relative power line.

import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import 'diplomacy_panel_rows.dart';

/// Localized tier word for a [PowerComparisonTier] per
/// `SPEC/ui/diplomacy-panel.md` § Relative power line.
String relativePowerTierLabel(AppLocalizations l10n, PowerComparisonTier tier) {
  return switch (tier) {
    PowerComparisonTier.vastlyInferior =>
      l10n.diplomacy_relativePower_tierVastlyInferior,
    PowerComparisonTier.inferior => l10n.diplomacy_relativePower_tierInferior,
    PowerComparisonTier.roughlyEqual =>
      l10n.diplomacy_relativePower_tierRoughlyEqual,
    PowerComparisonTier.superior => l10n.diplomacy_relativePower_tierSuperior,
    PowerComparisonTier.vastlySuperior =>
      l10n.diplomacy_relativePower_tierVastlySuperior,
  };
}

/// Renders the relative-power line shared by the diplomacy panel row and the
/// diplomacy detail screen per `SPEC/ui/diplomacy-panel.md` § Relative power
/// line and `SPEC/ui/diplomacy-detail-screen.md` § Current relation.
///
/// Structure: a muted `Relative power:` prefix, the existing signed
/// percentage ([formatPowerComparisonPercent]) in `--danger` (when [pct] > 0)
/// or `--success` (when [pct] <= 0) semibold, and the [PowerComparisonTier]
/// word in the same color, separated by a middle dot. The line wraps to extra
/// lines at narrow viewports (no `TextOverflow.ellipsis`) and exposes a
/// combined `semanticsLabel` plus an explanatory [Tooltip].
class RelativePowerLine extends StatelessWidget {
  const RelativePowerLine({super.key, required this.pct});

  /// `powerComparisonPercent` value comparing the target GP power score to the
  /// human player's.
  final int pct;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);

    // SPEC § Relative power line: percentage + tier share one color —
    // --danger when the GP is stronger (pct > 0), --success when at or below
    // the player (pct <= 0, including 0%). Resolved from the editorial-monocle
    // palette so the line matches the dark theme rather than raw Material reds.
    final Color valueColor = pct > 0
        ? EditorialMonoclePalette.danger
        : EditorialMonoclePalette.success;

    final String labelText = l10n.diplomacy_relativePower_label;
    final String pctText = formatPowerComparisonPercent(pct);
    final String tierText = relativePowerTierLabel(
      l10n,
      powerComparisonTier(pct),
    );

    final TextStyle labelStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
          color: EditorialMonoclePalette.muted,
        );
    final TextStyle pctStyle =
        (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
          color: valueColor,
          fontWeight: FontWeight.w600,
        );
    final TextStyle tierStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
          color: valueColor,
        );

    return Tooltip(
      message: l10n.diplomacy_relativePower_tooltip,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: '$labelText ', style: labelStyle),
            TextSpan(text: pctText, style: pctStyle),
            // Middle dot (U+00B7) separator, muted like the prefix.
            TextSpan(text: ' \u00b7 ', style: labelStyle),
            TextSpan(text: tierText, style: tierStyle),
          ],
        ),
        semanticsLabel: l10n.diplomacy_relativePower_semantics(pctText, tierText),
      ),
    );
  }
}
