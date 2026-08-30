import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show homeFleetIdFor, resolveNavalCombineTargetFleetId;

import 'province_panel_labels.dart';

String overlayFleetDisplayName(AppLocalizations l10n, Fleet fleet) {
  if (fleet.id == homeFleetIdFor(fleet.ownerId)) {
    return l10n.naval_homeFleetLabel;
  }
  return l10n.naval_fleetLabel(fleet.id);
}

String overlayFleetShipMixLine({
  required AppLocalizations l10n,
  required Fleet fleet,
}) {
  final byType = <String, int>{};
  for (final s in fleet.ships) {
    byType[s.typeId] = (byType[s.typeId] ?? 0) + 1;
  }
  if (byType.isEmpty) {
    return l10n.provinceOverlay_combineFleetsEmptyMix;
  }
  final keys = byType.keys.toList()..sort();
  return [
    for (final k in keys) '${shipTypeDisplayLabel(l10n, k)}: ${byType[k]}',
  ].join(', ');
}

String overlayFleetCombineConfirmMessage({
  required AppLocalizations l10n,
  required String humanPlayerId,
  required List<Fleet> fleets,
}) {
  final lines = <String>[
    for (final fleet in fleets)
      l10n.provinceOverlay_combineFleetsFleetLine(
        overlayFleetDisplayName(l10n, fleet),
        overlayFleetShipMixLine(l10n: l10n, fleet: fleet),
      ),
  ];
  final targetId = resolveNavalCombineTargetFleetId(
    humanPlayerId: humanPlayerId,
    fleetIdsInPreferOrder: [for (final f in fleets) f.id],
  );
  final survivor = fleets.firstWhere((f) => f.id == targetId);
  final survivorLine = survivor.id == homeFleetIdFor(humanPlayerId)
      ? l10n.provinceOverlay_combineFleetsSurvivorHome
      : l10n.provinceOverlay_combineFleetsSurvivorOther(
          overlayFleetDisplayName(l10n, survivor),
        );
  return '${lines.join('\n')}\n\n${l10n.provinceOverlay_combineFleetsConfirmEffect}\n$survivorLine';
}
