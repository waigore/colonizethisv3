import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_test_harness_common.dart';

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

/// OW minor + NW tribe combat [Game] for reactive dialogue integration tests.
Game turnTestOwNwMinorTribeAttackGame() {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  return ensureMilitaryArmiesForGame(
    Game(
      id: 'g1',
      globalGameSeed: 99,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: const [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'human'),
            Province(id: '$ow|P2', regionId: ow, ownerId: 'mn1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'grenadiers',
              ownerId: 'human',
              locationProvinceId: '$ow|P1',
            ),
            Unit(
              id: 'm1',
              type: 'peasant_levies',
              ownerId: 'mn1',
              locationProvinceId: '$ow|P2',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: const [
            Province(id: '$nw|N1', regionId: nw, ownerId: 'human'),
            Province(id: '$nw|N2', regionId: nw, ownerId: 'tr1'),
          ],
          units: [
            Unit(
              id: 'u2',
              type: 'grenadiers',
              ownerId: 'human',
              locationProvinceId: '$nw|N1',
            ),
            Unit(
              id: 't1',
              type: 'peasant_levies',
              ownerId: 'tr1',
              locationProvinceId: '$nw|N2',
            ),
          ],
        ),
      ),
      players: const [
        Player(id: 'human', displayName: 'Human', isHuman: true),
        Player(id: 'ai1', displayName: 'AI', isHuman: false),
      ],
      minorNations: const [MinorNation(id: 'mn1')],
      tribes: const [Tribe(id: 'tr1')],
      overtureStates: const [
        OvertureState(
          gpId: 'ai1',
          targetId: 'mn1',
          stage: OvertureStage.embassy,
        ),
        OvertureState(
          gpId: 'ai1',
          targetId: 'tr1',
          stage: OvertureStage.embassy,
        ),
      ],
    ),
  );
}

/// Topology for [turnTestOwNwMinorTribeAttackGame].
MapTopology turnTestOwNwMinorTribeAttackTopology() {
  return MapTopology(
    nodes: const [
      TopologyNode(
        id: 'P1',
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: kRegionOldWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'N1',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'N2',
        regionId: kRegionNewWorld,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'P1', id2: 'P2'),
      TopologyEdge(id1: 'N1', id2: 'N2'),
    ],
  );
}
