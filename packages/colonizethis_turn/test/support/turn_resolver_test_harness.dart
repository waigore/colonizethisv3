import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Old World region id for two-province integration setups in turn tests.
const turnTestOldWorldRegionId = 'oldWorld';

/// Fixed [Game.globalGameSeed] for spy/fog integration tests so spy-resolution
/// kill rolls stay deterministic (unset seed uses [Random] per
/// [spyPhaseRandom]).
const turnTestSpyFogGameSeed = 42;

/// Two Old World provinces; when [adjacent] is true they share a topology edge.
MapTopology twoAdjacentOldWorldProvinceTopology({
  String id1 = 'P1',
  String id2 = 'P2',
  String regionId = turnTestOldWorldRegionId,
  bool adjacent = true,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: id1,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: id2,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: adjacent
        ? [TopologyEdge(id1: id1, id2: id2)]
        : const <TopologyEdge>[],
  );
}

/// Prefixed Old World province id for [adjacentOwP1P2Game] setups (`oldWorld|P1`).
String turnTestOwProvinceId(String localId) =>
    '$turnTestOldWorldRegionId|$localId';

/// One owner block in [turnTestOwProvinceStacksFixture] (local ids `prefix0`…).
typedef TurnTestOwProvinceStack = ({
  String ownerId,
  int count,
  String localIdPrefix,
});

/// OW [Game] + province-only [MapTopology] from stacked owner blocks.
///
/// Used by military-victory integration scenarios (mass-province maps).
({Game game, MapTopology topology}) turnTestOwProvinceStacksFixture({
  required List<TurnTestOwProvinceStack> stacks,
  int turnNumber = 0,
  List<Player>? players,
  String gameId = 'g1',
}) {
  const ow = turnTestOldWorldRegionId;
  final provinces = <Province>[];
  final nodes = <TopologyNode>[];
  for (final stack in stacks) {
    for (var i = 0; i < stack.count; i++) {
      final localId = '${stack.localIdPrefix}$i';
      provinces.add(
        Province(id: '$ow|$localId', regionId: ow, ownerId: stack.ownerId),
      );
      nodes.add(
        TopologyNode(
          id: localId,
          regionId: ow,
          type: TopologyNodeType.province,
        ),
      );
    }
  }
  final game = Game(
    id: gameId,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players:
        players ??
        const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
  );
  return (
    game: game,
    topology: MapTopology(nodes: nodes, edges: const []),
  );
}

/// Adjacent OW `P1`/`P2` game with empty New World.
///
/// Pair with [twoAdjacentOldWorldProvinceTopology] (topology stays separate).
/// Cross-region, sea/fleet, and mass-province maps stay hand-rolled.
Game adjacentOwP1P2Game({
  String id = 'g1',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 0,
  String province1OwnerId = 'p1',
  String province2OwnerId = 'p2',
  List<Unit> units = const [],
  List<Player>? players,
  int? globalGameSeed,
  CombatMode? defaultCombatMode,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  TileMapState? tileState,
  bool ensureMilitaryArmies = false,
}) {
  const ow = turnTestOldWorldRegionId;
  final game = Game(
    id: id,
    globalGameSeed: globalGameSeed,
    defaultCombatMode: defaultCombatMode,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: province1OwnerId),
          Province(id: '$ow|P2', regionId: ow, ownerId: province2OwnerId),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
      tileState: tileState ?? const TileMapState(),
    ),
    players:
        players ??
        const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
  );
  return ensureMilitaryArmies ? ensureMilitaryArmiesForGame(game) : game;
}

/// Runs [resolveTurnForGame] and returns the resolved [Game], failing on pending.
Game resolveTurnComplete({
  required Game game,
  required MapTopology topology,
  Orders orders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  TurnEventSink? eventSink,
  TurnPhase? startFromPhase,
}) {
  return requireTurnResolutionComplete(
    resolveTurnForGame(
      game: game,
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      eventSink: eventSink,
      startFromPhase: startFromPhase,
    ),
  );
}
