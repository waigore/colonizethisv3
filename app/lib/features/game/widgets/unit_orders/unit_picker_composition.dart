// Per-army / per-fleet composition lines for DLG20002 / DLG31003 (Refs #4385).
// SPEC/ui/overlay-army-move-picker-dialog.md, naval-mission-fleet-picker-dialog.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../panels/tree_builders/fleet_mission_label.dart';

const kUnitPickerCompositionSeparator = ' \u00b7 ';

/// Type-count line for [armyId] from that army's `regimentUnitIds` only.
///
/// Does not call `regimentTypeCountsForPlayer`.
List<String> armyPickerCompositionLines({
  required Game game,
  required String armyId,
  required AppLocalizations l10n,
}) {
  Army? army;
  for (final candidate in game.worldState.armies) {
    if (candidate.id == armyId) {
      army = candidate;
      break;
    }
  }
  if (army == null || army.regimentUnitIds.isEmpty) {
    return [l10n.military_units_noRegimentsAssigned];
  }
  final counts = <String, int>{};
  for (final unitId in army.regimentUnitIds) {
    final unit = game.worldState.tryGetUnitById(unitId);
    if (unit == null) continue;
    counts[unit.type] = (counts[unit.type] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return [l10n.military_units_noRegimentsAssigned];
  }
  final typeIds = counts.keys.toList()..sort();
  final parts = [
    for (final typeId in typeIds)
      l10n.military_units_typeCount(
        regimentTypeDisplayName(typeId),
        counts[typeId]!,
      ),
  ];
  return [parts.join(kUnitPickerCompositionSeparator)];
}

/// True when [fleetIds] mixes in-port and at-sea fleets.
bool fleetPickerShowsLocationContext(Game game, List<String> fleetIds) {
  var sawAtSea = false;
  var sawInPort = false;
  for (final id in fleetIds) {
    final fleet = game.fleetById(id);
    if (fleet == null) continue;
    if (fleet.isAtSea) sawAtSea = true;
    if (fleet.isInPort) sawInPort = true;
    if (sawAtSea && sawInPort) return true;
  }
  return false;
}

/// Composition / mission / location lines for [fleetId].
List<String> fleetPickerCompositionLines({
  required Game game,
  required String fleetId,
  required AppLocalizations l10n,
  required bool showLocationContext,
}) {
  final fleet = game.fleetById(fleetId);
  if (fleet == null) {
    return [l10n.naval_units_compositionSummary(0, 0, 0)];
  }
  final agg = _fleetShipRoleCounts(fleet);
  final lines = <String>[
    l10n.naval_units_compositionSummary(agg.total, agg.warships, agg.merchants),
  ];
  if (fleet.mission != FleetMission.none) {
    lines.add(
      l10n.naval_mission_pendingLine(fleetMissionDisplayLabel(fleet.mission)),
    );
  }
  if (showLocationContext) {
    lines.add(
      fleet.isAtSea ? l10n.naval_units_locAtSea : l10n.naval_units_locInPort,
    );
  }
  return lines;
}

({int total, int warships, int merchants}) _fleetShipRoleCounts(Fleet fleet) {
  var warships = 0;
  var merchants = 0;
  for (final typeId in fleet.shipTypeIds) {
    if (NavalStatsCatalog.get(typeId).cargoHold > 0) {
      merchants += 1;
    } else {
      warships += 1;
    }
  }
  return (
    total: fleet.shipTypeIds.length,
    warships: warships,
    merchants: merchants,
  );
}
