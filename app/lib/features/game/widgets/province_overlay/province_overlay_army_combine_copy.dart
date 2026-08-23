import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../../flame/map_state/province_army_combine_action_state.dart';
import 'province_panel_labels.dart';

String overlayArmyDisplayName(AppLocalizations l10n, Army army) {
  if (army.isHomeArmy) return l10n.military_units_homeArmy;
  return l10n.military_units_army(army.id);
}

String overlayArmyRegimentMixLine({
  required AppLocalizations l10n,
  required Game game,
  required Army army,
}) {
  final units = game.worldState.allUnitsById;
  final byType = <String, int>{};
  for (final id in army.regimentUnitIds) {
    final unit = units[id];
    final type = unit?.type ?? id;
    byType[type] = (byType[type] ?? 0) + 1;
  }
  if (byType.isEmpty) {
    return l10n.provinceOverlay_combineArmiesEmptyMix;
  }
  final keys = byType.keys.toList()..sort();
  return [
    for (final k in keys) '${regimentTypeDisplayLabel(l10n, k)}: ${byType[k]}',
  ].join(', ');
}

String overlayArmyCombineConfirmMessage({
  required AppLocalizations l10n,
  required Game game,
  required List<Army> armies,
}) {
  final lines = <String>[
    for (final army in armies)
      l10n.provinceOverlay_combineArmiesArmyLine(
        overlayArmyDisplayName(l10n, army),
        overlayArmyRegimentMixLine(l10n: l10n, game: game, army: army),
      ),
  ];
  final survivor = overlayCombineSurvivor(armies);
  final survivorLine = survivor.isHomeArmy
      ? l10n.provinceOverlay_combineArmiesSurvivorHome
      : l10n.provinceOverlay_combineArmiesSurvivorField(
          overlayArmyDisplayName(l10n, survivor),
        );
  return '${lines.join('\n')}\n\n${l10n.provinceOverlay_combineArmiesConfirmEffect}\n$survivorLine';
}
