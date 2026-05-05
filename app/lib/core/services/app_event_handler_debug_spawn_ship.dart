import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers.dart';

/// Debug spawn ships into the human player's home fleet at capital.
DebugCommandResult applyDebugShipSpawnAtCapitalHomeFleet({
  required Game? currentGame,
  required SpawnDebugShipAtCapitalHomeFleetEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug spawn ignored: no active game.');
  }
  final player = findPlayerById(currentGame, event.humanPlayerId);
  if (player == null) {
    return (
      game: null,
      message: 'Debug spawn ignored: unknown player ${event.humanPlayerId}.',
    );
  }
  if (!player.isHuman) {
    return (
      game: null,
      message:
          'Debug spawn ignored: player ${event.humanPlayerId} is not human.',
    );
  }
  if (ShipEconomyCatalog.byId[event.shipTypeId] == null) {
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported ship type ${event.shipTypeId}.',
    );
  }
  if (event.count < 1) {
    return (game: null, message: 'Debug spawn ignored: count must be >= 1.');
  }
  final capitalProvinceId = player.capitalProvinceId;
  if (capitalProvinceId == null || capitalProvinceId.isEmpty) {
    return (
      game: null,
      message: 'Debug spawn ignored: player has no capital province.',
    );
  }
  final homeFleetId = homeFleetIdFor(event.humanPlayerId);
  final fleetIndex = currentGame.worldState.fleets.indexWhere(
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
  final world = currentGame.worldState;
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
  final nextGame = currentGame.copyWith(
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
