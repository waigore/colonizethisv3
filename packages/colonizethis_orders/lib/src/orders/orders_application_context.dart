import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'orders_logging.dart';

final ordersApplicationLog = ordersLog;

/// Counter-spy: per-turn kill chance = (friendlySpies * [counterSpyKillChancePercentPerSpy])%,
/// capped at [counterSpyKillChanceCapPercent]%. SPEC: work order resolution.
const int counterSpyKillChancePercentPerSpy = 5;
const int counterSpyKillChanceCapPercent = 30;

/// Per-turn chance (0–1) that a spy on steal_tech work successfully steals one tech from target.
const double spyTechStealChance = 0.08;

/// Old- and new-world unit-by-id snapshots for the work pipeline, folded into a
/// single record so callers never branch on a separate `isOldWorld` boolean to
/// pick one of two parallel maps (Refs #3404). The `oldWorld` field holds the
/// [kRegionOldWorld] units; `newWorld` holds [kRegionNewWorld] (`new` is a Dart
/// keyword, so the fields are named `oldWorld` / `newWorld`).
typedef WorkUnitsById = ({
  Map<String, Unit> oldWorld,
  Map<String, Unit> newWorld,
});

/// Canonical mutable clone of a `Map<String, Unit>` snapshot for the orders work
/// pipeline. Centralises the raw unit-by-id map clone into one call site so the
/// pattern is not repeated (Refs #3404; enforced by
/// `repo.orders_dedup_map_clones`). Returns a mutable copy so existing callers
/// can keep mutating the snapshot in place.
Map<String, Unit> copyUnitsById(Map<String, Unit> source) =>
    <String, Unit>{...source};

/// Immutable work-phase scratch (copy-on-write updates per #1958).
class WorkOrderState {
  const WorkOrderState({
    required this.unitsById,
    required this.tileState,
    required this.visibilityByTile,
    required this.portsByProvinceSeaboard,
    required this.purchasedTilesByTileKey,
    required this.oldProvinces,
    required this.newProvinces,
    this.updatedPlayers = const [],
  });

  final WorkUnitsById unitsById;
  final TileMapState tileState;
  final Map<String, Map<String, String>> visibilityByTile;
  final Map<String, String> portsByProvinceSeaboard;
  final Map<String, String> purchasedTilesByTileKey;
  final List<Province> oldProvinces;
  final List<Province> newProvinces;
  final List<Player> updatedPlayers;

  /// Unit-id snapshot for the requested region: [oldWorld] `true` selects the
  /// [kRegionOldWorld] map, `false` the [kRegionNewWorld] map.
  Map<String, Unit> unitsByIdForRegion(bool oldWorld) =>
      oldWorld ? unitsById.oldWorld : unitsById.newWorld;

  /// Copy with [units] replacing the requested region's unit-id snapshot.
  WorkOrderState withUnitsByIdForRegion(bool oldWorld, Map<String, Unit> units) =>
      copyWith(
        unitsById: oldWorld
            ? (oldWorld: units, newWorld: unitsById.newWorld)
            : (oldWorld: unitsById.oldWorld, newWorld: units),
      );

  /// The unit with [unitId] looked up across both region snapshots, or `null`.
  Unit? unitById(String unitId) =>
      unitsById.oldWorld[unitId] ?? unitsById.newWorld[unitId];

  /// Region id ([kRegionOldWorld] / [kRegionNewWorld]) that [unitId] belongs to;
  /// defaults to [kRegionNewWorld] when absent from the old-world snapshot.
  String regionIdForUnitId(String unitId) =>
      unitsById.oldWorld.containsKey(unitId)
      ? kRegionOldWorld
      : kRegionNewWorld;

  WorkOrderState copyWith({
    WorkUnitsById? unitsById,
    TileMapState? tileState,
    Map<String, Map<String, String>>? visibilityByTile,
    Map<String, String>? portsByProvinceSeaboard,
    Map<String, String>? purchasedTilesByTileKey,
    List<Province>? oldProvinces,
    List<Province>? newProvinces,
    List<Player>? updatedPlayers,
  }) {
    return WorkOrderState(
      unitsById: unitsById ?? this.unitsById,
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
    this.recruitWorkerOrders = const <String, List<RecruitWorkerOrder>>{},
    this.topology,
    this.tileMapByRegion,
    this.onDialogue,
    this.onWorkOrderTrace,
    required this.work,
  });

  final Game game;

  /// Player id -> queued worker recruit / train orders applied in the worker
  /// pool sub-phase of Build / work, **before** [buildOrders]. SPEC/game/
  /// workers-and-population.md § Phase placement.
  final Map<String, List<RecruitWorkerOrder>> recruitWorkerOrders;

  final Map<String, List<BuildUnitOrder>> buildOrders;
  final Map<String, List<WorkOrder>> workOrders;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(DialogueEvent)? onDialogue;
  final WorkOrderTraceCallback? onWorkOrderTrace;
  final WorkOrderState work;

  BuildWorkState copyWith({
    Game? game,
    Map<String, List<RecruitWorkerOrder>>? recruitWorkerOrders,
    Map<String, List<BuildUnitOrder>>? buildOrders,
    Map<String, List<WorkOrder>>? workOrders,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
    void Function(DialogueEvent)? onDialogue,
    WorkOrderTraceCallback? onWorkOrderTrace,
    WorkOrderState? work,
  }) {
    return BuildWorkState(
      game: game ?? this.game,
      recruitWorkerOrders: recruitWorkerOrders ?? this.recruitWorkerOrders,
      buildOrders: buildOrders ?? this.buildOrders,
      workOrders: workOrders ?? this.workOrders,
      topology: topology ?? this.topology,
      tileMapByRegion: tileMapByRegion ?? this.tileMapByRegion,
      onDialogue: onDialogue ?? this.onDialogue,
      onWorkOrderTrace: onWorkOrderTrace ?? this.onWorkOrderTrace,
      work: work ?? this.work,
    );
  }
}

/// Writes projected economy fields back onto [player] inside [current.game].
BuildWorkState writebackPlayerEconomyFields(
  BuildWorkState current,
  Player player, {
  required WorkerPool workers,
  required Stockpile stockpile,
  required int treasury,
}) {
  return current.copyWith(
    game: current.game.copyWith(
      players: current.game.players
          .map(
            (p) => p.id == player.id
                ? p.copyWith(
                    workerPool: workers,
                    stockpile: stockpile,
                    treasury: treasury,
                  )
                : p,
          )
          .toList(),
    ),
  );
}

/// Returns [game] with [newUnitId] appended to the appropriate army for [player].
///
/// When [armiesById] is supplied it MUST be a snapshot of `game.worldState.armies`
/// keyed by army id (see [armiesByIdForWorld]). It enables O(1) existence
/// lookup and bypasses the per-call `indexWhere` over `worldState.armies`,
/// which would otherwise be O(armyCount) per recruited unit and degrade build
/// phases that spawn many regiments for the same player. Refs #2394,
/// SPEC/program/order-suggestions.md § Throughput bounds.
///
/// The function mutates [armiesById] in place so subsequent calls observe the
/// just-updated/added entry: callers can build the map once at the start of a
/// build phase and pass the same reference across every recruit. Pass `null`
/// (or omit) to fall back to a single-pass scan that preserves the legacy
/// behavior for one-off uses.
Game appendMilitaryRegimentToArmy(
  Game game,
  Player player,
  String spawnProvinceId,
  String newUnitId, {
  Map<String, Army>? armiesById,
}) {
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

  // O(1) hot-path: when the caller supplied a snapshot map, look up by id and
  // require ownership match; missing entries fall back to the linear scan in
  // case the supplied map was built before a recent army insertion. Refs #2394.
  final Army? existing;
  if (armiesById != null) {
    final candidate = armiesById[armyId];
    existing = (candidate != null && candidate.ownerId == player.id)
        ? candidate
        : _firstArmyByIdAndOwner(ws.armies, armyId, player.id);
  } else {
    existing = _firstArmyByIdAndOwner(ws.armies, armyId, player.id);
  }
  if (existing != null) {
    final updated = existing.copyWith(
      regimentUnitIds: [...existing.regimentUnitIds, newUnitId],
    );
    final next = <Army>[
      for (final a in ws.armies)
        if (a.id == armyId && a.ownerId == player.id) updated else a,
    ];
    armiesById?[armyId] = updated;
    return game.withArmies(next);
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
  armiesById?[newArmy.id] = newArmy;
  return game.withArmies(next);
}

Army? _firstArmyByIdAndOwner(List<Army> armies, String armyId, String ownerId) {
  for (final a in armies) {
    if (a.id == armyId && a.ownerId == ownerId) return a;
  }
  return null;
}
