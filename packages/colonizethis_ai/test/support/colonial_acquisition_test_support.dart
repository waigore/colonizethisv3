/// Shared fixtures for COLONIAL acquisition pins (Refs #3972).
///
/// Owns parameterized [buildColonialAcquisitionGame], relation / overture
/// helpers, [buildColonialAcquisitionSnapshot], and merchant / colony
/// factories so `colonial_phase_planner_acquisition_*_test.dart` keep only
/// method-specific assertions and `reason` strings.
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'colonial_phase_planner_test_support.dart';

export 'colonial_phase_planner_test_support.dart'
    show
        ExpandEconomyPlan,
        kColonialPhaseGp1,
        kColonialPhaseGp2,
        kColonialPhaseMinor1,
        kColonialPhaseTribe1,
        kColonialPhaseTribe2,
        kNwTreasuryRecoveryOverridePlan;
export 'colonial_acquisition_test_support_distance.dart';

/// Default two-GP roster used by most acquisition pins (gp1 treasury patched
/// by [buildColonialAcquisitionGame]).
const List<Player> kColonialAcquisitionDefaultPlayers = <Player>[
  Player(
    id: kColonialPhaseGp1,
    displayName: 'GP1',
    isHuman: false,
    treasury: 100000,
  ),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
];

/// Default tribe1 / tribe2 roster for acquisition pins.
const List<Tribe> kColonialAcquisitionDefaultTribes = <Tribe>[
  Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
  Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
];

/// Default minor1 roster for Join Empire minor-target pins.
const List<MinorNation> kColonialAcquisitionDefaultMinors = <MinorNation>[
  MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
];

/// Canonical NW province owned by tribe1.
const String kColonialAcquisitionNwProv1 = 'newWorld|tribe1_a';

/// Canonical NW province owned by tribe2.
const String kColonialAcquisitionNwProv2 = 'newWorld|tribe2_b';

/// Canonical NW province owned by gp2 (GP-skip pins).
const String kColonialAcquisitionNwProvGp = 'newWorld|gp2_c';

/// Canonical tile key inside [kColonialAcquisitionNwProv1].
const String kColonialAcquisitionNwTile1 = 'newWorld|tribe1_a|1|1';

/// Alternate tile key inside [kColonialAcquisitionNwProv1].
const String kColonialAcquisitionNwTile1Alt = 'newWorld|tribe1_a|2|2';

/// Canonical tile key inside [kColonialAcquisitionNwProv2].
const String kColonialAcquisitionNwTile2 = 'newWorld|tribe2_b|1|1';

/// Friendly / at-peace diplomacy row (Join Empire / purchase_land gates).
DiplomacyRelation colonialAcquisitionFriendly(
  String a,
  String b, {
  num score = 60,
}) => DiplomacyRelation(
  factionId1: a,
  factionId2: b,
  score: score,
  level: RelationLevel.friendly,
);

/// Hostile at-war diplomacy row (purchase_land / declareWar skip pins).
DiplomacyRelation colonialAcquisitionAtWar(
  String a,
  String b, {
  num score = 10,
}) => DiplomacyRelation(
  factionId1: a,
  factionId2: b,
  score: score,
  level: RelationLevel.hostile,
  state: RelationState.atWar,
);

/// Neutral at-peace diplomacy row (declareWar null-relation controls).
DiplomacyRelation colonialAcquisitionPeaceNeutral(
  String a,
  String b, {
  num score = 40,
}) => DiplomacyRelation(
  factionId1: a,
  factionId2: b,
  score: score,
  level: RelationLevel.neutral,
);

/// NAP-stage overture (Join Empire gate).
OvertureState colonialAcquisitionNap(
  String gpId,
  String targetId, {
  int sinceTurn = 100,
}) => OvertureState(
  gpId: gpId,
  targetId: targetId,
  stage: OvertureStage.nap,
  sinceTurn: sinceTurn,
);

/// Embassy-stage overture (purchase_land gate).
OvertureState colonialAcquisitionEmbassy(
  String gpId,
  String targetId, {
  int sinceTurn = 100,
}) => OvertureState(
  gpId: gpId,
  targetId: targetId,
  stage: OvertureStage.embassy,
  sinceTurn: sinceTurn,
);

/// Trade-consulate overture (below embassy — purchase_land skip pin).
OvertureState colonialAcquisitionTradeConsulate(
  String gpId,
  String targetId, {
  int sinceTurn = 100,
}) => OvertureState(
  gpId: gpId,
  targetId: targetId,
  stage: OvertureStage.tradeConsulate,
  sinceTurn: sinceTurn,
);

/// Idle (or [status]) Merchant owned by [ownerId] on [provinceId].
Unit colonialAcquisitionMerchant(
  String id, {
  String ownerId = kColonialPhaseGp1,
  String provinceId = kColonialAcquisitionNwProv1,
  UnitStatus status = UnitStatus.idle,
  String tileSuffix = '5|5',
}) => Unit(
  id: id,
  type: kUnitTypeMerchant,
  ownerId: ownerId,
  locationProvinceId: provinceId,
  tileKey: '$provinceId|$tileSuffix',
  status: status,
);

/// Own-colony row for the active GP ([kColonialPhaseGp1]).
ColonyState colonialAcquisitionOwnColony(
  String tribeId, {
  String colonyOfGpId = kColonialPhaseGp1,
  int sinceTurn = 100,
}) => ColonyState(
  tribeId: tribeId,
  colonyOfGpId: colonyOfGpId,
  sinceTurn: sinceTurn,
);

/// Parameterized NW acquisition Game shared by all acquisition pin families.
///
/// Covers former local `_acquisitionGame` / `_purchaseLandGame` /
/// `_declareWarGame` / `_bothValidGame` shapes. Callers pass only the
/// fields their arm needs (units, armies, prospected tiles, colonies, …).
Game buildColonialAcquisitionGame({
  String gameIdPrefix = 'g-colonial-acquisition',
  String? gameId,
  int turnNumber = 130,
  int activePlayerTreasury = 100000,
  List<Province> newWorldProvinces = const [],
  List<Unit> newWorldUnits = const [],
  List<Army> armies = const [],
  Map<String, String> resourceByTileKey = const {},
  Set<String> prospectedTilesForGp1 = const {},
  Map<String, String> purchasedTiles = const {},
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<ColonyState> colonyStates = const [],
  List<Player>? players,
  List<Tribe>? tribes,
  List<MinorNation> minorNations = const [],
  String activePlayerId = kColonialPhaseGp1,
}) {
  final resolvedPlayers = players ?? kColonialAcquisitionDefaultPlayers;
  final patchedPlayers = <Player>[
    for (final p in resolvedPlayers)
      if (p.id == activePlayerId)
        p.copyWith(treasury: activePlayerTreasury)
      else
        p,
  ];
  return Game(
    id: gameId ?? '$gameIdPrefix-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      armies: armies,
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: prospectedTilesForGp1.isEmpty
          ? const <String, Set<String>>{}
          : <String, Set<String>>{activePlayerId: prospectedTilesForGp1},
      purchasedTilesByTileKey: purchasedTiles,
    ),
    players: patchedPlayers,
    tribes: tribes ?? kColonialAcquisitionDefaultTribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
    colonyStates: colonyStates,
  );
}

/// Snapshot for acquisition pins (optional distance-ordered invadable list).
AIWorldSnapshot buildColonialAcquisitionSnapshot({
  required List<String> invadableNw,
  List<String> invadableNwByDistance = const [],
  String playerId = kColonialPhaseGp1,
  int treasury = 100000,
  int newWorldProvincesOwned = 0,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      invadableNewWorldProvinceIdsByDistance: invadableNwByDistance,
      newWorldProvincesOwned: newWorldProvincesOwned,
    ),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}
