import 'package:colonizethis_models/colonizethis_models.dart';

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
  final isHomeFleet = orig.id == 'fleet_$humanPlayerId';

  final updatedFleets = <Fleet>[
    ...game.worldState.fleets.where((f) => f.id != orig.id),
    if (remainingShips.isNotEmpty || isHomeFleet) updatedOriginal,
    newFleet,
  ];

  return game.copyWith(
    worldState: game.worldState.copyWith(fleets: updatedFleets),
  );
}
