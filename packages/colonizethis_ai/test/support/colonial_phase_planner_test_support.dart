/// Shared fixtures for COLONIAL military / naval / lite / civilian / peace
/// unit pins (Refs #3967 / #3972).
///
/// Owns faction id constants, [buildColonialPhaseGame],
/// [buildColonialPhaseSnapshot], lite / civilian / peace helpers,
/// [kNwTreasuryRecoveryOverridePlan], and
/// [buildLockRecoveryBelowQuotaSnapshot] so planner `*_test.dart` files
/// keep only planner-specific assertions.
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';

export 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;

/// OW province id used by phase-planner dispatch COLONIAL / lite scaffolds.
const String kColonialPhaseDispatchOwProvGp1 = 'oldWorld|gp1_a';

/// Invadable OW minor province for dispatch EXPAND / COLONIAL-lite scaffolds.
const String kColonialPhaseDispatchOwProvMinor = 'oldWorld|m1_a';

/// Default active GP id used by most COLONIAL military / naval pins.
const String kColonialPhaseGp1 = 'gp1';

/// Peer GP id for multi-player isolation pins.
const String kColonialPhaseGp2 = 'gp2';

/// Third GP id for multi-owner / isolation pins.
const String kColonialPhaseGp3 = 'gp3';

/// Fourth GP id for COLONIAL peace multi-peer pins.
const String kColonialPhaseGp4 = 'gp4';

/// Default tribe id for NW invasion-target pins.
const String kColonialPhaseTribe1 = 'tribe1';

/// Second tribe id for multi-tribe at-war pins.
const String kColonialPhaseTribe2 = 'tribe2';

/// Third tribe id for COLONIAL-lite overture union pins.
const String kColonialPhaseTribe3 = 'tribe3';

/// Default minor-nation id for mixed-owner pins.
const String kColonialPhaseMinor1 = 'minor1';

/// Canonical NW province id used by Path E lock-recovery waiver pins.
const String kColonialPhaseNwProvTribeA = 'newWorld|tribe1_a';

/// Minimum at-quota OW province count per GP for COLONIAL peace pins.
///
/// Matches `kObserverConquestMinOwProvincesPerGp = 10`.
const int kColonialPeaceOwProvincesAtQuota = 10;

/// Expand-economy override that arms NW treasury-recovery Path E.
const ExpandEconomyPlan kNwTreasuryRecoveryOverridePlan = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

/// Default three-GP roster with high treasury for destination-filter pins.
const List<Player> kColonialPhaseDefaultPlayers = <Player>[
  Player(
    id: kColonialPhaseGp1,
    displayName: 'GP1',
    isHuman: false,
    treasury: 9999,
  ),
  Player(
    id: kColonialPhaseGp2,
    displayName: 'GP2',
    isHuman: false,
    treasury: 9999,
  ),
  Player(
    id: kColonialPhaseGp3,
    displayName: 'GP3',
    isHuman: false,
    treasury: 9999,
  ),
];

/// Three-GP roster without treasury overrides (COLONIAL-lite naval pins).
const List<Player> kColonialLiteNavalDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
  Player(id: kColonialPhaseGp3, displayName: 'GP3', isHuman: false),
];

/// Two-GP roster for COLONIAL-lite overture pins.
const List<Player> kColonialLiteOvertureDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
];

/// Two-GP roster for COLONIAL civilian pins.
const List<Player> kColonialCivilianDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
];

/// Four-GP roster for COLONIAL peace pins.
const List<Player> kColonialPeaceDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
  Player(id: kColonialPhaseGp3, displayName: 'GP3', isHuman: false),
  Player(id: kColonialPhaseGp4, displayName: 'GP4', isHuman: false),
];

/// Game scaffold for COLONIAL-phase / lite destination-filter pins.
///
/// New World provinces, players, tribes, and minors are passed in so each
/// test can shape ownership independently. Old World defaults to empty
/// because most planners do not query OW state for the destination filter
/// (the OW summary is read only for the outer quota gate).
Game buildColonialPhaseGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  List<Army> armies = const [],
  Map<String, String> resourceByTileKey = const {},
  TileMapState tileState = const TileMapState(),
  List<Player> players = kColonialPhaseDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
  String gameIdPrefix = 'g-2509-colonial-phase-planner',
  String? gameId,
}) {
  return Game(
    id: gameId ?? '$gameIdPrefix-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      armies: armies,
      resourceByTileKey: resourceByTileKey,
      tileState: tileState,
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
  );
}

/// Phase-planner dispatch COLONIAL-lite Game: turn ≥ 120, OW near quota
/// scaffold with a tribe-owned NW province (Refs #3977).
Game buildPhasePlannerDispatchColonialLiteGame({
  int turnNumber = kObserverColonialLiteMinTurn + 5,
  int regimentCount = 6,
  int ownTreasury = 9999,
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    gameId: 'g-2509-phase-planner-dispatch-expand-t$turnNumber',
    oldWorldProvinces: const [
      Province(
        id: kColonialPhaseDispatchOwProvGp1,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseGp1,
      ),
      Province(
        id: kColonialPhaseDispatchOwProvMinor,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseMinor1,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: kColonialPhaseNwProvTribeA,
        regionId: kNewWorldRegionId,
        ownerId: kColonialPhaseTribe1,
      ),
    ],
    armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: kColonialPhaseMinor1, displayName: 'Minor1'),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Phase-planner dispatch COLONIAL Game: OW at quota with NW invadable
/// tribe province and Home Army regiment count (Refs #3977).
Game buildPhasePlannerDispatchColonialGame({
  int regimentCount = 6,
  int ownTreasury = 9999,
}) {
  return buildColonialPhaseGame(
    turnNumber: 130,
    gameId: 'g-2509-phase-planner-dispatch-colonial',
    oldWorldProvinces: const [
      Province(
        id: kColonialPhaseDispatchOwProvGp1,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseGp1,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: kColonialPhaseNwProvTribeA,
        regionId: kNewWorldRegionId,
        ownerId: kColonialPhaseTribe1,
      ),
    ],
    armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Snapshot tuned for COLONIAL / COLONIAL-lite destination pins.
///
/// Own OW defaults to 10 (at quota). Tests shape `atWarWith`,
/// `invadableNw`, `invadableOw`, adjacent / preferred colonial lists,
/// and `oldWorldProvincesOwned` to exercise specific priority arms.
AIWorldSnapshot buildColonialPhaseSnapshot({
  List<String> atWarWith = const [],
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  List<String> adjacentNw = const [],
  List<String> preferredColonial = const [],
  int oldWorldProvincesOwned = 10,
  String playerId = kColonialPhaseGp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw,
      preferredColonialTargetFactionIdsSorted: preferredColonial,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Below-quota lock-recovery snapshot used by Path E waiver pins.
AIWorldSnapshot buildLockRecoveryBelowQuotaSnapshot({
  required List<String> invadableNw,
}) {
  return AIWorldSnapshot(
    playerId: kColonialPhaseGp1,
    threats: const ThreatSummary(atWarWith: [kColonialPhaseTribe1]),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 9,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: const [],
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      newWorldProvincesOwned: 0,
    ),
    economy: const EconomySummary(treasury: 0),
    relations: const {},
  );
}

/// COLONIAL-lite naval Game scaffold (turn 125, three-GP roster).
Game buildColonialLiteNavalGame({
  int turnNumber = 125,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = kColonialLiteNavalDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    newWorldProvinces: newWorldProvinces,
    oldWorldProvinces: oldWorldProvinces,
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    gameIdPrefix: 'g-2509-colonial-lite-naval',
  );
}

/// COLONIAL-lite naval snapshot (OW owned defaults to 9).
AIWorldSnapshot buildColonialLiteNavalSnapshot({
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  List<String> atWarWith = const [],
  int oldWorldProvincesOwned = 9,
  String playerId = kColonialPhaseGp1,
}) {
  return buildColonialPhaseSnapshot(
    atWarWith: atWarWith,
    invadableNw: invadableNw,
    invadableOw: invadableOw,
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    playerId: playerId,
  );
}

/// COLONIAL-lite overture Game scaffold (empty regions + overture rows).
Game buildColonialLiteOvertureGame({
  int turnNumber = 125,
  List<Player> players = kColonialLiteOvertureDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
    gameIdPrefix: 'g-2509-colonial-lite-overtures',
  );
}

/// COLONIAL-lite overture snapshot (OW owned defaults to 9).
AIWorldSnapshot buildColonialLiteOvertureSnapshot({
  List<String> adjacentNw = const [],
  List<String> preferredColonial = const [],
  int oldWorldProvincesOwned = 9,
  String playerId = kColonialPhaseGp1,
}) {
  return buildColonialPhaseSnapshot(
    adjacentNw: adjacentNw,
    preferredColonial: preferredColonial,
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    playerId: playerId,
  );
}

/// COLONIAL civilian Game scaffold (provinces + units + tile resources).
Game buildColonialCivilianGame({
  required List<Province> provinces,
  required List<Unit> owUnits,
  List<Unit> nwUnits = const [],
  Map<String, String> resourceByTileKey = const {},
  TileMapState tileState = const TileMapState(),
  List<Player> players = kColonialCivilianDefaultPlayers,
}) {
  final byRegion = <String, List<Province>>{};
  for (final province in provinces) {
    byRegion.putIfAbsent(province.regionId, () => <Province>[]).add(province);
  }
  return buildColonialPhaseGame(
    turnNumber: 132,
    oldWorldProvinces: byRegion[kOldWorldRegionId] ?? const [],
    newWorldProvinces: byRegion[kNewWorldRegionId] ?? const [],
    oldWorldUnits: owUnits,
    newWorldUnits: nwUnits,
    resourceByTileKey: resourceByTileKey,
    tileState: tileState,
    players: players,
    gameId: 'g-2509-colonial-phase-planner-civilian',
  );
}

/// Minimal snapshot for COLONIAL civilian in-module pins.
AIWorldSnapshot buildColonialCivilianSnapshot({
  String playerId = kColonialPhaseGp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Builds OW provinces owned by [ownerId] for COLONIAL peace quota pins.
List<Province> buildColonialPeaceOwProvincesForOwner(
  String ownerId, {
  int count = kColonialPeaceOwProvincesAtQuota,
}) {
  return [
    for (var i = 0; i < count; i++)
      Province(
        id: 'oldWorld|${ownerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownerId,
      ),
  ];
}

/// Default OW quota provinces for the four-GP COLONIAL peace roster.
List<Province> buildColonialPeaceDefaultOwQuotaProvinces({
  Map<String, int> perGpOwCounts = const {},
}) {
  return [
    for (final gp in const [
      kColonialPhaseGp1,
      kColonialPhaseGp2,
      kColonialPhaseGp3,
      kColonialPhaseGp4,
    ])
      ...buildColonialPeaceOwProvincesForOwner(
        gp,
        count: perGpOwCounts[gp] ?? kColonialPeaceOwProvincesAtQuota,
      ),
  ];
}

/// COLONIAL peace Game scaffold (four-GP roster at OW quota by default).
Game buildColonialPeaceGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province>? oldWorldProvinces,
  Map<String, int> perGpOwCounts = const {},
  List<Player> players = kColonialPeaceDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    newWorldProvinces: newWorldProvinces,
    oldWorldProvinces:
        oldWorldProvinces ??
        buildColonialPeaceDefaultOwQuotaProvinces(perGpOwCounts: perGpOwCounts),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    gameIdPrefix: 'g-2509-colonial-phase-planner-peace',
  );
}

/// Snapshot tuned for COLONIAL peace pins (OW owned defaults to 10).
AIWorldSnapshot buildColonialPeaceSnapshot({
  required List<String> atWarWith,
  List<String> invadableNw = const [],
  String playerId = kColonialPhaseGp1,
}) {
  return buildColonialPhaseSnapshot(
    atWarWith: atWarWith,
    invadableNw: invadableNw,
    playerId: playerId,
  );
}
