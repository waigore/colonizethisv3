// Shared orders-test game graphs (Refs #3971 wave 4).
//
// Parameterized builders for the high-frequency empty-region two-GP and
// owned-province shapes that previously reappeared across suggestion,
// engine, application, and validator fixture families. Prefer
// [TestFixtures.minimalGame] when isomorphic; keep specialized graphs only
// when topology/visibility/diplomacy deltas require it.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Default GP1 used by many diplomatic / suggestion fixtures.
const Player ordersCommonGp1 = Player(
  id: 'gp1',
  displayName: 'GP1',
  isHuman: true,
);

/// Default GP2 used by many diplomatic / suggestion fixtures.
const Player ordersCommonGp2 = Player(
  id: 'gp2',
  displayName: 'GP2',
  isHuman: false,
);

/// AI-style two-GP pair (both non-human) used by suggestion reuse fixtures.
const List<Player> ordersCommonTwoAiGps = [
  Player(id: 'gp1', displayName: 'GP1', isHuman: false),
  Player(id: 'gp2', displayName: 'GP2', isHuman: false),
];

/// Display-name `A`/`B` two-GP pair used by several API-impl fixtures.
const List<Player> ordersCommonTwoGpAb = [
  Player(id: 'gp1', displayName: 'A', isHuman: false),
  Player(id: 'gp2', displayName: 'B', isHuman: false),
];

/// Builds a [DiplomacyRelation] between [factionId1] and [factionId2].
DiplomacyRelation ordersGpRelation({
  String factionId1 = 'gp1',
  String factionId2 = 'gp2',
  RelationState state = RelationState.atPeace,
  RelationLevel level = RelationLevel.neutral,
  bool formalAlliance = false,
  num score = 50,
}) => DiplomacyRelation(
  factionId1: factionId1,
  factionId2: factionId2,
  state: state,
  level: level,
  formalAlliance: formalAlliance,
  score: score,
);

/// Province with optional prefixed id (`regionId|localId`).
Province ordersProvince({
  required String localId,
  String regionId = 'oldWorld',
  String? ownerId,
  bool prefixed = true,
}) => Province(
  id: prefixed ? '$regionId|$localId' : localId,
  regionId: regionId,
  ownerId: ownerId,
);

/// Empty both-regions game with two GPs and optional diplomacy extras.
///
/// Routes through [TestFixtures.minimalGame]; use [Game.copyWith] for fields
/// that factory does not expose (colony/boycott/alliance-break cooldowns,
/// seeds).
Game ordersTwoGpEmptyGame({
  String id = 'g1',
  int turnNumber = 1,
  List<Player>? players,
  List<DiplomacyRelation>? diplomacyRelations,
  RelationState state = RelationState.atPeace,
  RelationLevel level = RelationLevel.neutral,
  bool formalAlliance = false,
  num score = 50,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<OvertureState> overtureStates = const [],
}) {
  final resolvedPlayers = players ?? const [ordersCommonGp1, ordersCommonGp2];
  return TestFixtures.minimalGame(
    id: id,
    turnNumber: turnNumber,
    players: resolvedPlayers,
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtureStates,
    diplomacyRelations:
        diplomacyRelations ??
        [
          ordersGpRelation(
            state: state,
            level: level,
            formalAlliance: formalAlliance,
            score: score,
          ),
        ],
  );
}

/// Empty both-regions game with three GPs and peace relations from gp1 to
/// each other GP (default).
Game ordersThreeGpEmptyGame({
  String id = 'g1',
  int turnNumber = 1,
  List<Player>? players,
  List<DiplomacyRelation>? diplomacyRelations,
}) {
  final resolvedPlayers =
      players ??
      const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        Player(id: 'gp3', displayName: 'GP3', isHuman: false),
      ];
  return TestFixtures.minimalGame(
    id: id,
    turnNumber: turnNumber,
    players: resolvedPlayers,
    diplomacyRelations:
        diplomacyRelations ??
        [
          ordersGpRelation(factionId2: 'gp2'),
          ordersGpRelation(factionId2: 'gp3'),
        ],
  );
}

/// Old-world (or [regionId]) game with two owned provinces and two GPs.
Game ordersTwoProvinceOwnedGame({
  String id = 'g1',
  int turnNumber = 1,
  String regionId = 'oldWorld',
  String p1Local = 'p1',
  String p2Local = 'p2',
  String owner1 = 'gp1',
  String owner2 = 'gp2',
  bool prefixedIds = true,
  bool inNewWorld = false,
  List<Player>? players,
  List<Unit> units = const [],
  List<Army> armies = const [],
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  List<DiplomacyRelation>? diplomacyRelations,
  bool includeDefaultDiplomacy = false,
  RelationState state = RelationState.atPeace,
  num score = 50,
}) {
  final p1 = ordersProvince(
    localId: p1Local,
    regionId: regionId,
    ownerId: owner1,
    prefixed: prefixedIds,
  );
  final p2 = ordersProvince(
    localId: p2Local,
    regionId: regionId,
    ownerId: owner2,
    prefixed: prefixedIds,
  );
  final region = RegionData(provinces: [p1, p2], units: units);
  return TestFixtures.minimalGame(
    id: id,
    turnNumber: turnNumber,
    players: players ?? const [ordersCommonGp1, ordersCommonGp2],
    oldWorld: inNewWorld ? const RegionData() : region,
    newWorld: inNewWorld ? region : const RegionData(),
    armies: armies,
    playerVisibilityByTile: playerVisibilityByTile,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    diplomacyRelations:
        diplomacyRelations ??
        (includeDefaultDiplomacy
            ? [ordersGpRelation(state: state, score: score)]
            : const []),
  );
}

/// Dual-region owner map: OW p1/p2 (+ optional unowned p3) and NW n1.
Game ordersDualRegionOwnerMapGame({
  String id = 'g1',
  int turnNumber = 1,
  bool includeUnownedOwProvince = true,
  List<Player>? players,
}) {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  return TestFixtures.minimalGame(
    id: id,
    turnNumber: turnNumber,
    players: players ?? ordersCommonTwoGpAb,
    oldWorld: RegionData(
      provinces: [
        const Province(id: 'oldWorld|p1', regionId: ow, ownerId: 'gp1'),
        const Province(id: 'oldWorld|p2', regionId: ow, ownerId: 'gp2'),
        if (includeUnownedOwProvince)
          const Province(id: 'oldWorld|p3', regionId: ow),
      ],
      units: const [],
    ),
    newWorld: RegionData(
      provinces: const [
        Province(id: 'newWorld|n1', regionId: nw, ownerId: 'gp1'),
      ],
      units: const [],
    ),
  );
}

/// Flexible OW (or dual-region) game routed through [TestFixtures.minimalGame].
///
/// Use for family fixtures that need custom province/unit/army/visibility
/// knobs without re-stating `WorldState` / `TurnState` boilerplate (Refs #3971).
Game ordersOwRegionGame({
  String id = 'g1',
  int turnNumber = 0,
  required List<Player> players,
  required RegionData oldWorld,
  RegionData newWorld = const RegionData(),
  List<Army> armies = const [],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  Map<String, String>? resourceByTileKey,
  Map<String, String>? portsByProvinceSeaboard,
  Map<String, Set<String>>? playerProspectedTiles,
  TileMapState? tileState,
  Map<String, String>? purchasedTilesByTileKey,
  List<Fleet> fleets = const [],
}) => TestFixtures.minimalGame(
  id: id,
  turnNumber: turnNumber,
  players: players,
  oldWorld: oldWorld,
  newWorld: newWorld,
  armies: armies,
  fleets: fleets,
  tribes: tribes,
  minorNations: minorNations,
  overtureStates: overtureStates,
  diplomacyRelations: diplomacyRelations,
  playerVisibilityByTile: playerVisibilityByTile,
  tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  resourceByTileKey: resourceByTileKey,
  portsByProvinceSeaboard: portsByProvinceSeaboard,
  playerProspectedTiles: playerProspectedTiles,
  tileState: tileState,
  purchasedTilesByTileKey: purchasedTilesByTileKey,
);

/// Empty-edge topology nodes for every province in [region] (local ids).
MapTopology ordersProvinceTopology(
  Iterable<Province> provinces, {
  String regionId = 'oldWorld',
  List<TopologyEdge> edges = const [],
}) => MapTopology(
  nodes: [
    for (final p in provinces)
      TopologyNode(
        id: p.id.contains('|') ? p.id.split('|').last : p.id,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
  ],
  edges: edges,
);
