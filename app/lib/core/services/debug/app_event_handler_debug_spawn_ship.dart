import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Debug spawn ships into the human player's home fleet at capital.
DebugCommandResult applyDebugShipSpawnAtCapitalHomeFleet({
  required Game? currentGame,
  required SpawnDebugShipAtCapitalHomeFleetEvent event,
}) {
  final guard = resolveSpawnDebugGuards(
    currentGame: currentGame,
    label: DebugCommandLabel.spawn,
    playerId: event.humanPlayerId,
    requireHuman: true,
  );
  if (guard is DebugGuardFailure) return guard.result;
  guard as DebugGuardPass;
  final player = guard.player;
  if (ShipEconomyCatalog.byId[event.shipTypeId] == null) {
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported ship type ${event.shipTypeId}.',
    );
  }
  if (event.count < 1) {
    return debugCountBelowMin(DebugCommandLabel.spawn);
  }
  final capitalProvinceId = player.capitalProvinceId;
  if (capitalProvinceId == null || capitalProvinceId.isEmpty) {
    return debugNoCapitalProvince(DebugCommandLabel.spawn);
  }
  final homeFleetId = homeFleetIdFor(event.humanPlayerId);
  final fleetIndex = guard.game.worldState.fleets.indexWhere(
    (fleet) =>
        fleet.id == homeFleetId &&
        fleet.ownerId == event.humanPlayerId &&
        fleet.inPortAtProvinceId == capitalProvinceId &&
        fleet.regionId == ProvinceId.regionIdFrom(capitalProvinceId),
  );
  if (fleetIndex < 0) {
    return (
      game: null,
      message:
          'Debug spawn ignored: no valid home fleet at capital for player ${event.humanPlayerId}.',
    );
  }
  final boundedCount = event.count > 25 ? 25 : event.count;
  final world = guard.game.worldState;
  final fleets = List<Fleet>.from(world.fleets);
  final fleet = fleets[fleetIndex];
  var nextShipSeq = world.nextShipInstanceSeq;
  final inferredSeq = inferNextShipInstanceSeqFromFleets(fleets);
  if (nextShipSeq < inferredSeq) {
    nextShipSeq = inferredSeq;
  }
  final spawned = <ShipInstance>[];
  for (var i = 0; i < boundedCount; i++) {
    spawned.add(
      ShipInstance(id: 'ship_$nextShipSeq', typeId: event.shipTypeId),
    );
    nextShipSeq++;
  }
  fleets[fleetIndex] = fleet.copyWith(ships: [...fleet.ships, ...spawned]);
  final nextGame = guard.game.copyWith(
    worldState: world.copyWith(
      fleets: fleets,
      nextShipInstanceSeq: nextShipSeq,
    ),
  );
  return (
    game: nextGame,
    message:
        'Spawned ${spawned.length} ${event.shipTypeId} at ${player.displayName} capital home fleet.',
  );
}
