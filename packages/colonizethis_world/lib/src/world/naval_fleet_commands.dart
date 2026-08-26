import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_world_mutations.dart';
import 'military_list_helpers.dart';
import 'naval.dart';

/// Survivor fleet id for an all-ships combine: Home Fleet if present in
/// [fleetIdsInPreferOrder], else the first id in that list.
/// SPEC/ui/naval-units-fleet-management.md; overlay Refs #4659.
String resolveNavalCombineTargetFleetId({
  required String humanPlayerId,
  required List<String> fleetIdsInPreferOrder,
}) {
  if (fleetIdsInPreferOrder.isEmpty) {
    throw ArgumentError('fleetIdsInPreferOrder must not be empty');
  }
  final homeId = homeFleetIdFor(humanPlayerId);
  for (final id in fleetIdsInPreferOrder) {
    if (id == homeId) return id;
  }
  return fleetIdsInPreferOrder.first;
}

bool _fleetsShareCombineLocality(List<Fleet> fleets) {
  if (fleets.length < 2) return false;
  final allInPort = fleets.every((f) => f.inPortAtProvinceId != null);
  if (allInPort) {
    final port = fleets.first.inPortAtProvinceId!;
    return fleets.every((f) => f.inPortAtProvinceId == port);
  }
  final allAtSea = fleets.every(
    (f) => f.inPortAtProvinceId == null && f.seaZoneId != null,
  );
  if (!allAtSea) return false;
  final regionId = fleets.first.regionId;
  final sea = fleets.first.seaZoneId!;
  return fleets.every(
    (f) => f.regionId == regionId && f.seaZoneId == sea,
  );
}

/// Merges [fleetIds] into one fleet at the same port or sea zone.
/// Home Fleet is always the survivor when included; otherwise the first id in
/// [fleetIds] (caller supplies prefer order). Survivor mission becomes [FleetMission.none].
/// Empty non-Home fleets are removed; Home Fleet is retained even when empty.
/// SPEC/ui/naval-units-fleet-management.md; overlay Refs #4659.
Game applyNavalCombineFleets({
  required Game game,
  required String humanPlayerId,
  required List<String> fleetIds,
}) {
  if (fleetIds.length < 2) return game;
  final idSet = fleetIds.toSet();
  if (idSet.length < 2) return game;

  final selected = <Fleet>[
    for (final f in game.worldState.fleets)
      if (f.ownerId == humanPlayerId && idSet.contains(f.id)) f,
  ];
  if (selected.length < 2) return game;
  if (!_fleetsShareCombineLocality(selected)) return game;

  final preferOrder = <String>[
    for (final id in fleetIds)
      if (selected.any((f) => f.id == id)) id,
  ];
  final targetId = resolveNavalCombineTargetFleetId(
    humanPlayerId: humanPlayerId,
    fleetIdsInPreferOrder: preferOrder,
  );
  Fleet? target;
  for (final f in selected) {
    if (f.id == targetId) {
      target = f;
      break;
    }
  }
  if (target == null) return game;

  final mergedShips = <ShipInstance>[...target.ships];
  for (final f in selected) {
    if (f.id == targetId) continue;
    mergedShips.addAll(f.ships);
  }

  final merged = Fleet(
    id: targetId,
    ownerId: humanPlayerId,
    seaZoneId: target.seaZoneId,
    inPortAtProvinceId: target.inPortAtProvinceId,
    regionId: target.regionId,
    ships: mergedShips,
    mission: FleetMission.none,
  );

  final homeId = homeFleetIdFor(humanPlayerId);
  final updated = <Fleet>[
    for (final f in game.worldState.fleets)
      if (!idSet.contains(f.id)) f,
    merged,
  ].where((f) => f.ships.isNotEmpty || f.id == homeId).toList();

  return game.withFleets(updated);
}

/// Returns [game] unchanged if the fleet is missing or [shipInstanceIdsToNewFleet] is empty.
/// SPEC/ui/naval-units-fleet-management.md.
Game applyNavalSplitFleet({
  required Game game,
  required String humanPlayerId,
  required String originalFleetId,
  required List<String> shipInstanceIdsToNewFleet,
}) {
  if (shipInstanceIdsToNewFleet.isEmpty) return game;

  final originalFleet = fleetsByIdForWorld(game.worldState)[originalFleetId];
  if (originalFleet == null) return game;
  final orig = originalFleet;

  final idSet = shipInstanceIdsToNewFleet.toSet();
  final partitioned = partitionBySelectedIds(
    items: orig.ships,
    selectedIds: idSet,
    idOf: (s) => s.id,
  );
  final shipsToNewFleet = partitioned.selected;
  final remainingShips = partitioned.remaining;

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

  final byId = fleetsByIdForWorld(game.worldState);
  final sourceFleet = byId[sourceFleetId];
  final targetFleet = byId[targetFleetId];
  if (sourceFleet == null || targetFleet == null) {
    return game;
  }
  if (sourceFleet.ownerId != humanPlayerId ||
      targetFleet.ownerId != humanPlayerId) {
    return game;
  }

  final transferIds = shipInstanceIdsToTransfer.toSet();
  final partitioned = partitionBySelectedIds(
    items: sourceFleet.ships,
    selectedIds: transferIds,
    idOf: (s) => s.id,
  );
  final shipsToTransfer = partitioned.selected;
  final sourceRemaining = partitioned.remaining;
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
