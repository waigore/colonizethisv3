import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/army_ids.dart';

final ordersApplicationLog = packageLogger();

/// Counter-spy: per-turn kill chance = (friendlySpies * [counterSpyKillChancePercentPerSpy])%,
/// capped at [counterSpyKillChanceCapPercent]%. SPEC: work order resolution.
const int counterSpyKillChancePercentPerSpy = 5;
const int counterSpyKillChanceCapPercent = 30;

/// Per-turn chance (0–1) that a spy on steal_tech work successfully steals one tech from target.
const double spyTechStealChance = 0.08;

/// Immutable work-phase scratch (copy-on-write updates per #1958).
class WorkOrderState {
  const WorkOrderState({
    required this.oldUnitsById,
    required this.newUnitsById,
    required this.tileState,
    required this.visibilityByTile,
    required this.portsByProvinceSeaboard,
    required this.purchasedTilesByTileKey,
    required this.oldProvinces,
    required this.newProvinces,
    this.updatedPlayers = const [],
  });

  final Map<String, Unit> oldUnitsById;
  final Map<String, Unit> newUnitsById;
  final TileMapState tileState;
  final Map<String, Map<String, String>> visibilityByTile;
  final Map<String, String> portsByProvinceSeaboard;
  final Map<String, String> purchasedTilesByTileKey;
  final List<Province> oldProvinces;
  final List<Province> newProvinces;
  final List<Player> updatedPlayers;

  WorkOrderState copyWith({
    Map<String, Unit>? oldUnitsById,
    Map<String, Unit>? newUnitsById,
    TileMapState? tileState,
    Map<String, Map<String, String>>? visibilityByTile,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, String>? purchasedTilesByTileKey,
    List<Province>? oldProvinces,
    List<Province>? newProvinces,
    List<Player>? updatedPlayers,
  }) {
    return WorkOrderState(
      oldUnitsById: oldUnitsById ?? this.oldUnitsById,
      newUnitsById: newUnitsById ?? this.newUnitsById,
      tileState: tileState ?? this.tileState,
      visibilityByTile: visibilityByTile ?? this.visibilityByTile,
      portsByProvinceSeaboard:
          portsByProvinceSeaboard ?? this.portsByProvinceSeaboard,
      purchasedTilesByTileKey:
          purchasedTilesByTileKey ?? this.purchasedTilesByTileKey,
      oldProvinces: oldProvinces ?? this.oldProvinces,
      newProvinces: newProvinces ?? this.newProvinces,
      updatedPlayers: updatedPlayers ?? this.updatedPlayers,
    );
  }
}

/// Session context for applyBuildAndWorkOrders: game snapshot, order maps, map topology.
class BuildWorkState {
  const BuildWorkState({
    required this.game,
    required this.buildOrders,
    required this.workOrders,
    this.topology,
    this.tileMapByRegion,
    this.onDialogue,
    required this.work,
  });

  final Game game;
  final Map<String, List<BuildUnitOrder>> buildOrders;
  final Map<String, List<WorkOrder>> workOrders;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(DialogueEvent)? onDialogue;
  final WorkOrderState work;

  BuildWorkState copyWith({
    Game? game,
    Map<String, List<BuildUnitOrder>>? buildOrders,
    Map<String, List<WorkOrder>>? workOrders,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
    void Function(DialogueEvent)? onDialogue,
    WorkOrderState? work,
  }) {
    return BuildWorkState(
      game: game ?? this.game,
      buildOrders: buildOrders ?? this.buildOrders,
      workOrders: workOrders ?? this.workOrders,
      topology: topology ?? this.topology,
      tileMapByRegion: tileMapByRegion ?? this.tileMapByRegion,
      onDialogue: onDialogue ?? this.onDialogue,
      work: work ?? this.work,
    );
  }
}

/// Returns [game] with [newUnitId] appended to the appropriate army for [player].
Game appendMilitaryRegimentToArmy(
  Game game,
  Player player,
  String spawnProvinceId,
  String newUnitId,
) {
  final cap = player.capitalProvinceId;
  final atHome =
      cap != null &&
      (spawnProvinceId == cap ||
          (ProvinceId.regionIdFrom(spawnProvinceId) ==
                  ProvinceId.regionIdFrom(cap) &&
              ProvinceId.localIdFrom(spawnProvinceId) ==
                  ProvinceId.localIdFrom(cap)));
  final armyId = atHome
      ? homeArmyIdFor(player.id)
      : fieldArmyIdFor(player.id, spawnProvinceId);
  final ws = game.worldState;
  final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
  final idx = ws.armies.indexWhere(
    (a) => a.id == armyId && a.ownerId == player.id,
  );
  if (idx >= 0) {
    final a = ws.armies[idx];
    final updated = a.copyWith(
      regimentUnitIds: [...a.regimentUnitIds, newUnitId],
    );
    final next = List<Army>.from(ws.armies)..[idx] = updated;
    return game.copyWith(worldState: ws.copyWith(armies: next));
  }
  final stationed = atHome ? cap : spawnProvinceId;
  final newArmy = Army(
    id: armyId,
    ownerId: player.id,
    regionId: regionId,
    stationedProvinceId: stationed,
    regimentUnitIds: [newUnitId],
    isHomeArmy: atHome,
  );
  final next = [...ws.armies, newArmy]..sort((a, b) => a.id.compareTo(b.id));
  return game.copyWith(worldState: ws.copyWith(armies: next));
}
