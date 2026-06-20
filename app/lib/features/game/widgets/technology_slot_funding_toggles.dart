// Compact per-slot research-funding selector for `TechnologyPanel`.
// Split out of `technology_panel.dart` so that file stays under the
// 700-line `repo.game_widgets_file_size` cap. Refs #3512.
//
// SPEC: `SPEC/ui/technology-panel.md` § Slot behaviour > Slot funding
// controls (Refs #3512). Renders the five `ResearchFundingLevel` values as
// compact rectangular toggles; the toggle matching the slot's current
// funding paints the selected (`--accent`) chrome, the rest the unselected
// (`--border`) outline.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';

/// Localized label for a research [ResearchFundingLevel] funding toggle.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Slot funding controls.
String fundingLevelLabel(AppLocalizations l10n, ResearchFundingLevel level) {
  return switch (level) {
    ResearchFundingLevel.none => l10n.technologyPanel_fundingNone,
    ResearchFundingLevel.low => l10n.technologyPanel_fundingLow,
    ResearchFundingLevel.medium => l10n.technologyPanel_fundingMedium,
    ResearchFundingLevel.high => l10n.technologyPanel_fundingHigh,
    ResearchFundingLevel.maximum => l10n.technologyPanel_fundingMaximum,
  };
}

/// Compact row of five rectangular research-funding toggle controls, in the
/// fixed order None, Low, Medium, High, Maximum (one per
/// [ResearchFundingLevel]). The toggle matching [selected] renders in the
/// selected state; tapping a toggle invokes [onChanged] with its level.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Slot funding controls
/// (Refs #3512).
class SlotFundingToggleRow extends StatelessWidget {
  const SlotFundingToggleRow({
    super.key,
    required this.slotIndex,
    required this.selected,
    required this.onChanged,
  });

  final int slotIndex;
  final ResearchFundingLevel selected;
  final ValueChanged<ResearchFundingLevel> onChanged;

  /// Stable widget-test key for the toggle of [level] in slot [slotIndex].
  /// Keeps tests decoupled from localized labels. Refs #3512.
  static Key toggleKey(int slotIndex, ResearchFundingLevel level) {
    return ValueKey<String>('techFundingToggle_${slotIndex}_${level.name}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        for (final level in ResearchFundingLevel.values)
          _FundingToggle(
            key: toggleKey(slotIndex, level),
            label: fundingLevelLabel(l10n, level),
            selected: level == selected,
            onTap: () => onChanged(level),
          ),
      ],
    );
  }
}

class _FundingToggle extends StatelessWidget {
  const _FundingToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        selected ? EditorialMonoclePalette.accent : EditorialMonoclePalette.border;
    final Color? fill = selected
        ? EditorialMonoclePalette.accent.withValues(alpha: 0.18)
        : null;
    final Color labelColor = selected
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.muted;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.04,
            ),
          ),
        ),
      ),
    );
  }
}
