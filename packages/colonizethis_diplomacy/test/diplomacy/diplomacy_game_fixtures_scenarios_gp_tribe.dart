// GP–tribe and related diplomacy fixture scenarios (Refs #4130 wave-5 densify).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

const _ow = 'oldWorld';
const _nw = 'newWorld';

/// Shared topology for GP–tribe first-contact tests with no sea routes.
const gpTribeEmptyTopology = MapTopology(nodes: [], edges: []);

/// Old World coastal province sea-connected to an unrevealed New World tribe
/// colony, with zero New World tile visibility (Refs #3463, #3825).
const gpTribeSeaReachableTopology = MapTopology(
  nodes: [
    TopologyNode(id: '$_ow|home', regionId: _ow, type: TopologyNodeType.province),
    TopologyNode(id: '$_ow|owSea', regionId: _ow, type: TopologyNodeType.seaZone),
    TopologyNode(id: '$_nw|nwSea', regionId: _nw, type: TopologyNodeType.seaZone),
    TopologyNode(id: '$_nw|colony', regionId: _nw, type: TopologyNodeType.province),
  ],
  edges: [
    TopologyEdge(id1: '$_ow|home', id2: '$_ow|owSea'),
    TopologyEdge(id1: '$_ow|owSea', id2: '$_nw|nwSea'),
    TopologyEdge(id1: '$_nw|nwSea', id2: '$_nw|colony'),
  ],
);

const _mayaTribe = Tribe(id: 'tribe1', displayName: 'Maya', capitalProvinceId: '$_nw|t1');
const _spainGp = Player(id: 'gp1', displayName: 'Spain', isHuman: true);

Map<String, Map<String, String>> _nwTileVisibility(String tileKey) => {
      'gp1': {tileKey: 'fullyVisible'},
    };

Map<String, Map<String, List<String>>> _nwTileKeys(String provId, String tileKey) => {
      _nw: {provId: [tileKey]},
    };

/// Human GP with NW tribe colony visibility and no GP–Tribe relation (Refs #3825).
Game gpTribeFirstContactGame({
  String id = 'g',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 3,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, Map<String, String>>? playerVisibilityByTile,
}) =>
    diplomacyGame(
      id: id,
      phase: phase,
      turnNumber: turnNumber,
      players: const [_spainGp],
      oldWorld: RegionData(
        provinces: [Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1')],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$_nw|t1',
            regionId: _nw,
            ownerId: 'tribe1',
            displayName: 'Maya Capital',
          ),
        ],
      ),
      playerVisibilityByTile: playerVisibilityByTile ?? _nwTileVisibility('$_nw|t1|0|0'),
      tileKeysByRegionAndProvince:
          tileKeysByRegionAndProvince ?? _nwTileKeys('$_nw|t1', '$_nw|t1|0|0'),
      tribes: const [_mayaTribe],
      diplomacyRelations: const [],
    );

/// Sea-reachable tribe colony with zero NW tile visibility (Refs #3825).
Game gpTribeSeaReachableNoNwVisibilityGame({String id = 'g_sea'}) => diplomacyGame(
      id: id,
      turnNumber: 1,
      players: const [_spainGp],
      oldWorld: const RegionData(
        provinces: [Province(id: '$_ow|home', regionId: _ow, ownerId: 'gp1')],
      ),
      newWorld: const RegionData(
        provinces: [Province(id: '$_nw|colony', regionId: _nw, ownerId: 'tribe1')],
      ),
      playerVisibilityByTile: const {'gp1': {'$_ow|home|0|0': 'fullyVisible'}},
      tileKeysByRegionAndProvince: const {
        _ow: {'$_ow|home': ['$_ow|home|0|0']},
        _nw: {'$_nw|colony': ['$_nw|colony|0|0']},
      },
      tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
      diplomacyRelations: const [],
    );

/// Human and AI GPs with shared NW tribe tile visibility (Refs #3825).
Game humanAndAiGpTribeVisibilityGame({
  Map<String, bool> aiControlByGpId = const {},
  TurnPhase phase = TurnPhase.endOfTurn,
  int turnNumber = 4,
}) =>
    diplomacyGame(
      phase: phase,
      turnNumber: turnNumber,
      players: const [
        _spainGp,
        Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1'),
          Province(id: '$_ow|p2', regionId: _ow, ownerId: 'gp2'),
        ],
      ),
      newWorld: RegionData(
        provinces: [Province(id: '$_nw|t1', regionId: _nw, ownerId: 'tribe1')],
      ),
      playerVisibilityByTile: {
        'gp1': {'$_nw|t1|0|0': 'fullyVisible'},
        'gp2': {'$_nw|t1|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: _nwTileKeys('$_nw|t1', '$_nw|t1|0|0'),
      tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
      aiControlByGpId: aiControlByGpId,
      diplomacyRelations: const [],
    );

/// GP with relation, visibility, and unit anchors for known-target tests.
Game knownDiplomaticTargetsAnchoredGame() => diplomacyGame(
      id: 'g',
      turnNumber: 3,
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      oldWorld: RegionData(
        provinces: const [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1'),
          Province(id: '$_ow|p2', regionId: _ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: '$_ow|p1',
          ),
        ],
      ),
      playerVisibilityByTile: const {'gp1': {'$_ow|p2|0|0': 'fullyVisible'}},
      tileKeysByRegionAndProvince: {
        _ow: {'$_ow|p2': ['$_ow|p2|0|0']},
      },
      minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      diplomacyRelations: const [
        DiplomacyRelation(factionId1: 'minor1', factionId2: 'gp1'),
      ],
    );

/// Survival peace tests: GPs at war with configurable OW province counts.
Game survivalPeaceProvinceGame({
  required String id,
  required int turnNumber,
  required Map<String, int> provinceCountsByGpId,
  required List<Player> players,
  required List<DiplomacyRelation> diplomacyRelations,
}) {
  final provinces = <Province>[];
  for (final entry in provinceCountsByGpId.entries) {
    for (var i = 1; i <= entry.value; i++) {
      provinces.add(
        Province(id: '$_ow|${entry.key}_$i', regionId: _ow, ownerId: entry.key),
      );
    }
  }
  return diplomacyGame(
    id: id,
    turnNumber: turnNumber,
    players: players,
    oldWorld: RegionData(provinces: provinces),
    diplomacyRelations: diplomacyRelations,
  );
}

/// Trade-slot / world-market bid-cap probe game (Refs #3825).
Game tradeSlotsBidCapTestGame({
  Map<String, bool> techUnlocked = const {},
  List<OvertureState> overtureStates = const [],
  List<Player> players = const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
}) =>
    diplomacyGame(
      players: techUnlocked.isEmpty
          ? players
          : players.map((p) => p.copyWith(techUnlocked: techUnlocked)).toList(),
      overtureStates: overtureStates,
    );

/// Isolated GP with no relations or visibility (known-target negative case).
Game knownDiplomaticTargetsIsolatedGame() => diplomacyGame(
      id: 'g',
      turnNumber: 1,
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      oldWorld: const RegionData(
        provinces: [Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1')],
      ),
    );
