import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'diplomatic_relation_lookup.dart';
import 'game_world_mutations.dart';
import 'naval.dart';
import 'province_lookup.dart';

/// O(1) mission lookup for naval order strings (Refs #2394).
final _fleetMissionByOrderName = <String, FleetMission>{
  for (final m in FleetMission.values) m.name: m,
};

FleetMission _fleetMissionFromOrderName(String name) =>
    _fleetMissionByOrderName[name] ?? FleetMission.none;

void _resyncFleetLookupMaps(
  List<Fleet> fleets,
  Map<String, Fleet> fleetById,
  Map<String, int> fleetIndexById,
) {
  fleetById.clear();
  fleetById.addEntries(fleets.map((f) => MapEntry(f.id, f)));
  fleetIndexById.clear();
  for (var i = 0; i < fleets.length; i++) {
    fleetIndexById[fleets[i].id] = i;
  }
}

List<Fleet> _applySingleNavalMissionOrder({
  required Game game,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required Map<String, int> fleetIndexById,
  required String playerId,
  required NavalMissionOrder order,
}) {
  final fleet = fleetById[order.fleetId];
  if (fleet == null || fleet.ownerId != playerId) return fleets;
  final homeFleetId = homeFleetIdFor(playerId);

  if (order.mission == 'join_home_fleet') {
    final homeFleet = fleetById[homeFleetId];
    if (homeFleet == null) return fleets;
    final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
    if (capitalProvinceId == null ||
        fleet.inPortAtProvinceId != capitalProvinceId) {
      return fleets;
    }
    if (fleet.shipTypeIds.isEmpty) return fleets;
    final updatedHome = homeFleet.copyWith(
      ships: [...homeFleet.ships, ...fleet.ships],
    );
    final next = fleets
        .where((f) => f.id != fleet.id)
        .map((f) => f.id == homeFleetId ? updatedHome : f)
        .toList();
    _resyncFleetLookupMaps(next, fleetById, fleetIndexById);
    return next;
  }

  if (fleet.id == homeFleetId) {
    return fleets;
  }
  final mission = _fleetMissionFromOrderName(order.mission);

  if (mission == FleetMission.blockade) {
    final targetProvinceId = order.targetProvinceId;
    final province =
        targetProvinceId != null &&
            targetProvinceId.isNotEmpty &&
            ProvinceId.isPrefixed(targetProvinceId)
        ? game.worldState.tryGetProvince(targetProvinceId)
        : null;
    final ownerId = province?.ownerId;
    final atWar =
        ownerId != null &&
        ownerId != playerId &&
        factionsAtWar(game, playerId, ownerId);
    if (!atWar) {
      final cleared = fleet.copyWith(
        mission: FleetMission.none,
        targetPortId: null,
        targetProvinceId: null,
      );
      final idx = fleetIndexById[fleet.id];
      if (idx != null) {
        final next = List<Fleet>.from(fleets)..[idx] = cleared;
        fleetById[fleet.id] = cleared;
        return next;
      }
      return fleets;
    }
  }

  final newFleet = fleet.copyWith(
    mission: mission,
    targetPortId: order.targetPortId,
    targetProvinceId: order.targetProvinceId,
  );
  final idx = fleetIndexById[fleet.id];
  if (idx != null) {
    final next = List<Fleet>.from(fleets)..[idx] = newFleet;
    fleetById[fleet.id] = newFleet;
    return next;
  }
  return fleets;
}

Game applyNavalMissionOrders(
  Game game,
  Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final fleetById = <String, Fleet>{};
  final fleetIndexById = <String, int>{};
  _resyncFleetLookupMaps(fleets, fleetById, fleetIndexById);

  for (final entry in navalMissionOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      fleets = _applySingleNavalMissionOrder(
        game: game,
        fleets: fleets,
        fleetById: fleetById,
        fleetIndexById: fleetIndexById,
        playerId: playerId,
        order: order,
      );
    }
  }

  for (var i = 0; i < fleets.length; i++) {
    final f = fleets[i];
    if (f.mission != FleetMission.blockade) continue;
    final targetProvinceId = f.targetProvinceId;
    if (targetProvinceId == null || targetProvinceId.isEmpty) continue;
    final province = ProvinceId.isPrefixed(targetProvinceId)
        ? game.worldState.tryGetProvince(targetProvinceId)
        : null;
    final ownerId = province?.ownerId;
    final atWar =
        ownerId != null &&
        ownerId != f.ownerId &&
        factionsAtWar(game, f.ownerId, ownerId);
    if (!atWar) {
      fleets = List<Fleet>.from(fleets)
        ..[i] = f.copyWith(
          mission: FleetMission.none,
          targetPortId: null,
          targetProvinceId: null,
        );
    }
  }

  return game.withFleets(fleets);
}
