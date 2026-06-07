import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_world_mutations.dart';
import 'naval.dart';

/// Returns [game] unchanged if the fleet is missing or [shipInstanceIdsToNewFleet] is empty.
/// SPEC/ui/naval-units-fleet-management.md.
Game applyNavalSplitFleet({
  required Game game,
  required String humanPlayerId,
  required String originalFleetId,
  required List<String> shipInstanceIdsToNewFleet,
}) {
  if (shipInstanceIdsToNewFleet.isEmpty) return game;

  Fleet? originalFleet;
  for (final f in game.worldState.fleets) {
    if (f.id == originalFleetId) {
      originalFleet = f;
      break;
    }
  }
  if (originalFleet == null) return game;
  final orig = originalFleet;

  final idSet = shipInstanceIdsToNewFleet.toSet();
  final shipsToNewFleet = orig.ships
      .where((s) => idSet.contains(s.id))
      .toList();
  final remainingShips = orig.ships
      .where((s) => !idSet.contains(s.id))
      .toList();

  final allFleetIds = game.worldState.fleets
      .map((f) => int.tryParse(f.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
  final maxId = allFleetIds.isEmpty
      ? 0
      : allFleetIds.reduce((a, b) => a > b ? a : b);
  final newFleetId = '${maxId + 1}';

  final newFleet = Fleet(
    id: newFleetId,
    ownerId: humanPlayerId,
    seaZoneId: orig.seaZoneId,
    inPortAtProvinceId: orig.inPortAtProvinceId,
    regionId: orig.regionId,
    ships: shipsToNewFleet,
    mission: FleetMission.none,
  );

  final updatedOriginal = orig.copyWith(ships: remainingShips);
  final isHomeFleet = orig.id == homeFleetIdFor(humanPlayerId);

  final updatedFleets = <Fleet>[
    ...game.worldState.fleets.where((f) => f.id != orig.id),
    if (remainingShips.isNotEmpty || isHomeFleet) updatedOriginal,
    newFleet,
  ];

  return game.withFleets(updatedFleets);
}

/// Transfers selected ship instances from [sourceFleetId] into [targetFleetId].
///
/// Immediate UI fleet-management operation (not a turn order). Returns [game]
/// unchanged when fleets are missing, owners mismatch, or no transferable ships
/// are selected.
Game applyNavalTransferShipsBetweenFleets({
  required Game game,
  required String humanPlayerId,
  required String sourceFleetId,
  required String targetFleetId,
  required List<String> shipInstanceIdsToTransfer,
}) {
  if (shipInstanceIdsToTransfer.isEmpty || sourceFleetId == targetFleetId) {
    return game;
  }

  Fleet? sourceFleet;
  Fleet? targetFleet;
  for (final fleet in game.worldState.fleets) {
    if (fleet.id == sourceFleetId) {
      sourceFleet = fleet;
    } else if (fleet.id == targetFleetId) {
      targetFleet = fleet;
    }
  }
  if (sourceFleet == null || targetFleet == null) {
    return game;
  }
  if (sourceFleet.ownerId != humanPlayerId ||
      targetFleet.ownerId != humanPlayerId) {
    return game;
  }

  final transferIds = shipInstanceIdsToTransfer.toSet();
  final shipsToTransfer = <ShipInstance>[];
  final sourceRemaining = <ShipInstance>[];
  for (final ship in sourceFleet.ships) {
    if (transferIds.contains(ship.id)) {
      shipsToTransfer.add(ship);
    } else {
      sourceRemaining.add(ship);
    }
  }
  if (shipsToTransfer.isEmpty) {
    return game;
  }

  final updatedTarget = targetFleet.copyWith(
    ships: [...targetFleet.ships, ...shipsToTransfer],
    mission: FleetMission.none,
  );
  final sourceIsHomeFleet = sourceFleet.id == homeFleetIdFor(humanPlayerId);
  final updatedSource = sourceFleet.copyWith(ships: sourceRemaining);

  final updatedFleets = <Fleet>[
    for (final fleet in game.worldState.fleets) ...[
      if (fleet.id == targetFleet.id)
        updatedTarget
      else if (fleet.id == sourceFleet.id)
        if (sourceRemaining.isNotEmpty || sourceIsHomeFleet) updatedSource,
      if (fleet.id != targetFleet.id && fleet.id != sourceFleet.id) fleet,
    ],
  ];

  return game.withFleets(updatedFleets);
}
