// Localized force/fort/Details lines for CMPT10001. Refs #4438.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../province_overlay/province_panel_labels.dart';
import '../unit_orders/move_army_invasion_intel_labels.dart';
import 'combat_mode_choice_intel.dart';

List<String> combatModeChoiceDefaultForceLines(
  AppLocalizations l10n,
  CombatModeChoiceIntel intel,
) {
  final lines = <String>[
    l10n.moveArmy_yourArmyRegiments(intel.ownRegimentCount),
  ];
  if (intel.defendersUnknown) {
    lines.add(l10n.moveArmy_defendersUnknown);
  } else if (intel.enemyRegimentCount != null) {
    final n = intel.enemyRegimentCount!;
    lines.add(
      intel.role == CombatModeChoiceRole.defender
          ? l10n.combatMode_attackersRegiments(n)
          : l10n.moveArmy_defendersRegiments(n),
    );
  }
  final fortLevel = intel.fortLevel;
  if (fortLevel != null) {
    lines.add(moveArmyFortLabelForLevel(l10n, fortLevel));
  }
  return lines;
}

List<String> combatModeChoiceDetailTypeLines(
  AppLocalizations l10n,
  CombatModeChoiceIntel intel,
) {
  final lines = <String>[];
  void addTypes(Map<String, int> byType) {
    for (final entry in byType.entries) {
      lines.add(
        l10n.provinceOverlay_indentedCount(
          regimentTypeDisplayLabel(l10n, entry.key),
          entry.value,
        ),
      );
    }
  }

  addTypes(intel.ownTypesByRegimentId);
  if (!intel.defendersUnknown && intel.enemyRegimentCount != null) {
    addTypes(intel.enemyTypesByRegimentId);
  }
  return lines;
}
