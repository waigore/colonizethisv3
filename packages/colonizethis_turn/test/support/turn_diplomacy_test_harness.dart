import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Fixed [Game.globalGameSeed] for spy/fog integration tests so spy-resolution
/// kill rolls stay deterministic (unset seed uses [Random] per
/// [spyPhaseRandom]).
const turnTestSpyFogGameSeed = 42;

/// Minimal OW [Game] with provinces and optional fleets / diplomacy.
Game turnTestOwGame({
  String id = 'g1',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 0,
  required List<Province> provinces,
  List<Fleet> fleets = const [],
  List<Player>? players,
  List<DiplomacyRelation>? diplomacyRelations,
  List<Unit> units = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces, units: units),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players:
        players ??
        const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
    diplomacyRelations: diplomacyRelations ?? const [],
  );
}

/// OW+NW cross-region [Game] with one owned province per region.
Game turnTestOwNwCrossRegionGame({
  String ownerId = 'p1',
  List<Unit> owUnits = const [],
  List<Unit> nwUnits = const [],
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
}) {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: ownerId),
        ],
        units: owUnits,
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: '$nw|P2', regionId: nw, ownerId: ownerId),
        ],
        units: nwUnits,
      ),
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
    ),
    players: [Player(id: ownerId, displayName: 'A', isHuman: true)],
  );
}

/// OW+NW [Game] with same local id `P1` in both regions for spy/fog decay tests.
Game turnTestSpyFogOwNwSameLocalIdGame({
  int turnNumber = 1,
  TurnPhase phase = TurnPhase.endOfTurn,
  List<Unit> owUnits = const [],
}) {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  const tileKeyOwP1 = 'oldWorld|P1|0|0';
  const tileKeyNwP1 = 'newWorld|P1|0|0';
  return Game(
    id: 'g1',
    globalGameSeed: turnTestSpyFogGameSeed,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
        ],
        units: owUnits,
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: '$nw|P1', regionId: nw, ownerId: 'p2'),
        ],
      ),
      playerVisibilityByTile: {
        'p1': {
          tileKeyOwP1: VisibilityLevel.fullyVisible.name,
          tileKeyNwP1: VisibilityLevel.fullyVisible.name,
        },
        'p2': {},
      },
      tileKeysByRegionAndProvince: {
        ow: {
          'P1': [tileKeyOwP1],
          'P2': ['oldWorld|P2|0|0'],
        },
        nw: {
          'P1': [tileKeyNwP1],
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
}

/// Topology for [turnTestSpyFogOwNwSameLocalIdGame] (three provinces, no edges).
MapTopology turnTestSpyFogOwNwSameLocalIdTopology() {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  return MapTopology(
    nodes: const [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'P1', regionId: nw, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
}
