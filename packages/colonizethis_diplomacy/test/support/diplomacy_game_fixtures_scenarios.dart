import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures_base.dart';

/// Shared entry for subsidy resolver tests (alias for [gpMinorEmbassySubsidyGame]).
Game subsidyResolverGame({
  String id = 'g1',
  int turnNumber = 2,
  int gp1Treasury = 10_000,
  RelationState relationState = RelationState.atPeace,
  List<OvertureState> overtureStates = const [
    OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    ),
  ],
  List<SubsidyState> subsidyStates = const [
    SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10),
  ],
  bool includeSubsidy = true,
  bool includeDiplomaticExpertiseTech = false,
}) =>
    gpMinorEmbassySubsidyGame(
      id: id,
      turnNumber: turnNumber,
      gp1Treasury: gp1Treasury,
      relationState: relationState,
      overtureStates: overtureStates,
      subsidyStates: subsidyStates,
      includeSubsidy: includeSubsidy,
      includeDiplomaticExpertiseTech: includeDiplomaticExpertiseTech,
    );

/// GP + Minor with embassy overture for subsidy and grant-aid tests.
Game gpMinorEmbassySubsidyGame({
  String id = 'g1',
  int turnNumber = 2,
  int gp1Treasury = 10_000,
  RelationState relationState = RelationState.atPeace,
  List<OvertureState> overtureStates = const [
    OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    ),
  ],
  List<SubsidyState> subsidyStates = const [
    SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10),
  ],
  bool includeSubsidy = true,
  bool includeDiplomaticExpertiseTech = false,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          treasury: gp1Treasury,
          techUnlocked: includeDiplomaticExpertiseTech
              ? const {kTechIdDiplomaticExpertise: true}
              : null,
        ),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          state: relationState,
          score: 50,
        ),
      ],
      overtureStates: overtureStates,
      subsidyStates: includeSubsidy ? subsidyStates : const [],
    );

/// Two GPs with mutual embassy overtures (FTP resolver tests).
Game gpGpEmbassyGame({
  String id = 'ftp-test',
  int turnNumber = 3,
  int relationScore = 70,
  Set<String> existingFtpKeys = const {},
  bool gp2Human = false,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: [
        const Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: relationScore,
          level: RelationLevel.friendly,
        ),
      ],
      overtureStates: const [
        OvertureState(
          gpId: 'gp1',
          targetId: 'gp2',
          stage: OvertureStage.embassy,
        ),
        OvertureState(
          gpId: 'gp2',
          targetId: 'gp1',
          stage: OvertureStage.embassy,
        ),
      ],
      ftpPartnershipKeys: existingFtpKeys,
    );

/// Intervention dedup: one aggressor GP, one AI investor, two minors at war.
Game twoMinorWarGame({
  String id = 'g',
  int turnNumber = 4,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: const [
        Player(id: 'gp_attacker', displayName: 'Aggressor', isHuman: false),
        Player(id: 'gp_ai', displayName: 'AI Investor', isHuman: false),
      ],
      minorNations: const [
        MinorNation(id: 'minor1', displayName: 'Minor 1'),
        MinorNation(id: 'minor2', displayName: 'Minor 2'),
      ],
      overtureStates: const [
        OvertureState(
          gpId: 'gp_ai',
          targetId: 'minor1',
          stage: OvertureStage.embassy,
          sinceTurn: 0,
        ),
        OvertureState(
          gpId: 'gp_ai',
          targetId: 'minor2',
          stage: OvertureStage.embassy,
          sinceTurn: 0,
        ),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp_attacker',
          factionId2: 'minor1',
          state: RelationState.atPeace,
        ),
        DiplomacyRelation(
          factionId1: 'gp_attacker',
          factionId2: 'minor2',
          state: RelationState.atPeace,
        ),
      ],
    );

/// Shared `Game` fixture for dossier evidence rule tests (`test/dossier/`).
///
/// Builds on [TestFixtures.minimalGame] (Refs #3715, #3825).
Game evidenceGame({
  String id = 'g1',
  int turnNumber = 2,
  required List<Player> players,
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<DiplomaticEvent> diplomaticHistoryEvents = const [],
  Map<String, bool> aiControlByGpId = const {},
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: players,
      diplomacyRelations: diplomacyRelations,
      diplomaticHistoryEvents: diplomaticHistoryEvents,
      aiControlByGpId: aiControlByGpId,
      lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
      lastHumanResearchCategoryCompletionTurn:
          lastHumanResearchCategoryCompletionTurn,
    );

/// Shared topology for GP–tribe first-contact tests with no sea routes.
const gpTribeEmptyTopology = MapTopology(nodes: [], edges: []);

/// Old World coastal province sea-connected to an unrevealed New World tribe
/// colony, with zero New World tile visibility (Refs #3463, #3825).
const gpTribeSeaReachableTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|owSea',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSea',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|colony',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
    TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
    TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
  ],
);

/// Human GP with NW tribe colony visibility and no GP–Tribe relation (Refs #3825).
Game gpTribeFirstContactGame({
  String id = 'g',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 3,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, Map<String, String>>? playerVisibilityByTile,
}) {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  return diplomacyGame(
    id: id,
    phase: phase,
    turnNumber: turnNumber,
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
      ],
    ),
    newWorld: RegionData(
      provinces: [
        Province(
          id: '$nw|t1',
          regionId: nw,
          ownerId: 'tribe1',
          displayName: 'Maya Capital',
        ),
      ],
    ),
    playerVisibilityByTile: playerVisibilityByTile ??
        const {
          'gp1': {'$nw|t1|0|0': 'fullyVisible'},
        },
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ??
        {
          nw: {
            '$nw|t1': ['$nw|t1|0|0'],
          },
        },
    tribes: const [
      Tribe(
        id: 'tribe1',
        displayName: 'Maya',
        capitalProvinceId: '$nw|t1',
      ),
    ],
    diplomacyRelations: const [],
  );
}

/// Sea-reachable tribe colony with zero NW tile visibility (Refs #3825).
Game gpTribeSeaReachableNoNwVisibilityGame({String id = 'g_sea'}) =>
    diplomacyGame(
      id: id,
      turnNumber: 1,
      players: const [
        Player(id: 'gp1', displayName: 'Spain', isHuman: true),
      ],
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      playerVisibilityByTile: const {
        'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|home': ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': ['newWorld|colony|0|0'],
        },
      },
      tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
      diplomacyRelations: const [],
    );

/// Human and AI GPs with shared NW tribe tile visibility (Refs #3825).
Game humanAndAiGpTribeVisibilityGame({
  Map<String, bool> aiControlByGpId = const {},
  TurnPhase phase = TurnPhase.endOfTurn,
  int turnNumber = 4,
}) {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  return diplomacyGame(
    phase: phase,
    turnNumber: turnNumber,
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
      Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
      ],
    ),
    newWorld: RegionData(
      provinces: [
        Province(id: '$nw|t1', regionId: nw, ownerId: 'tribe1'),
      ],
    ),
    playerVisibilityByTile: const {
      'gp1': {'$nw|t1|0|0': 'fullyVisible'},
      'gp2': {'$nw|t1|0|0': 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: const {
      nw: {
        '$nw|t1': ['$nw|t1|0|0'],
      },
    },
    tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
    aiControlByGpId: aiControlByGpId,
    diplomacyRelations: const [],
  );
}

const _knownTargetsOw = 'oldWorld';

/// GP with relation, visibility, and unit anchors for known-target tests.
Game knownDiplomaticTargetsAnchoredGame() => diplomacyGame(
      id: 'g',
      turnNumber: 3,
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: '$_knownTargetsOw|p1',
            regionId: _knownTargetsOw,
            ownerId: 'gp1',
          ),
          Province(
            id: '$_knownTargetsOw|p2',
            regionId: _knownTargetsOw,
            ownerId: 'minor1',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: '$_knownTargetsOw|p1',
          ),
        ],
      ),
      playerVisibilityByTile: const {
        'gp1': {'$_knownTargetsOw|p2|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: const {
        _knownTargetsOw: {
          '$_knownTargetsOw|p2': ['$_knownTargetsOw|p2|0|0'],
        },
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
        Province(
          id: 'oldWorld|${entry.key}_$i',
          regionId: 'oldWorld',
          ownerId: entry.key,
        ),
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
  List<Player> players = const [
    Player(id: 'gp1', displayName: 'GP1', isHuman: true),
  ],
}) =>
    diplomacyGame(
      players: players
          .map(
            (p) => techUnlocked.isEmpty
                ? p
                : p.copyWith(techUnlocked: techUnlocked),
          )
          .toList(),
      overtureStates: overtureStates,
    );

/// Isolated GP with no relations or visibility (known-target negative case).
Game knownDiplomaticTargetsIsolatedGame() => diplomacyGame(
      id: 'g',
      turnNumber: 1,
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: '$_knownTargetsOw|p1',
            regionId: _knownTargetsOw,
            ownerId: 'gp1',
          ),
        ],
      ),
    );
