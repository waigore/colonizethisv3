// Localized invasion intel lines for DLG20001. SPEC/ui/move-army-dialog.md (#4216).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'move_army_invasion_intel.dart';

String moveArmyFortLabelForLevel(AppLocalizations l10n, int fortLevel) {
  return switch (fortLevel) {
    0 => l10n.moveArmy_fortOpenField,
    1 => l10n.moveArmy_fortWoodSiege,
    2 => l10n.moveArmy_fortStoneSiege,
    3 => l10n.moveArmy_fortModernSiege,
    _ => l10n.moveArmy_fortModernSiege,
  };
}

/// Siege gist for Wood/Stone/Modern forts. Null for open field / missing intel.
String? moveArmyFortSiegeGistForLevel(
  AppLocalizations l10n,
  int? fortLevel, {
  bool defenderRole = false,
}) {
  if (fortLevel == null || fortLevel <= 0) return null;
  if (defenderRole) {
    return switch (fortLevel) {
      1 => l10n.moveArmy_fortSiegeGistWoodDefender,
      2 => l10n.moveArmy_fortSiegeGistStoneDefender,
      _ => l10n.moveArmy_fortSiegeGistModernDefender,
    };
  }
  return switch (fortLevel) {
    1 => l10n.moveArmy_fortSiegeGistWood,
    2 => l10n.moveArmy_fortSiegeGistStone,
    _ => l10n.moveArmy_fortSiegeGistModern,
  };
}

List<String> moveArmyInvasionIntelSummaryLines(
  AppLocalizations l10n,
  MoveArmyInvasionIntelSummary summary,
) {
  if (summary.intelLevel == MoveArmyInvasionIntelLevel.unknown) {
    return [l10n.moveArmy_defendersUnknown];
  }
  final lines = <String>[];
  if (summary.unopposed) {
    lines.add(l10n.moveArmy_unopposedCapture);
  } else {
    lines.add(
      l10n.moveArmy_defendersRegiments(summary.defenderCombatCapableCount!),
    );
  }
  lines.add(moveArmyFortLabelForLevel(l10n, summary.fortLevel!));
  return lines;
}

List<String> moveArmyInvasionIntelDetailTypeLines({
  required AppLocalizations l10n,
  required MoveArmyInvasionIntelSummary summary,
  required Map<String, int> ownTypesByRegimentId,
  required String Function(String regimentTypeId) regimentLabel,
}) {
  if (summary.intelLevel != MoveArmyInvasionIntelLevel.full) {
    return const [];
  }
  final lines = <String>[];
  for (final entry in ownTypesByRegimentId.entries) {
    lines.add(
      l10n.provinceOverlay_indentedCount(regimentLabel(entry.key), entry.value),
    );
  }
  for (final entry in summary.defenderTypesByRegimentId.entries) {
    lines.add(
      l10n.provinceOverlay_indentedCount(regimentLabel(entry.key), entry.value),
    );
  }
  return lines;
}
