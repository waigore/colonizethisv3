/// Shared fixtures for COLONIAL military / naval unit pins (Refs #3967).
///
/// Owns faction id constants, [buildColonialPhaseGame],
/// [buildColonialPhaseSnapshot], [kNwTreasuryRecoveryOverridePlan], and
/// [buildLockRecoveryBelowQuotaSnapshot] so
/// `colonial_phase_planner_military_test.dart` /
/// `colonial_phase_planner_naval_test.dart` keep only planner-specific
/// assertions.
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;

/// Default active GP id used by most COLONIAL military / naval pins.
const String kColonialPhaseGp1 = 'gp1';

/// Peer GP id for multi-player isolation pins.
const String kColonialPhaseGp2 = 'gp2';

/// Third GP id for multi-owner / isolation pins.
const String kColonialPhaseGp3 = 'gp3';

/// Default tribe id for NW invasion-target pins.
const String kColonialPhaseTribe1 = 'tribe1';

/// Second tribe id for multi-tribe at-war pins.
const String kColonialPhaseTribe2 = 'tribe2';

/// Default minor-nation id for mixed-owner pins.
const String kColonialPhaseMinor1 = 'minor1';

/// Canonical NW province id used by Path E lock-recovery waiver pins.
const String kColonialPhaseNwProvTribeA = 'newWorld|tribe1_a';

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

/// Game scaffold for COLONIAL-phase military / naval destination-filter pins.
///
/// New World provinces, players, tribes, and minors are passed in so each
/// test can shape ownership independently. Old World defaults to empty
/// because the planners do not query OW state for the destination filter
/// (the OW summary is read only for the outer quota gate).
Game buildColonialPhaseGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = kColonialPhaseDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  String gameIdPrefix = 'g-2509-colonial-phase-planner',
}) {
  return Game(
    id: '$gameIdPrefix-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot tuned for COLONIAL: own OW defaults to 10 (at quota).
///
/// Tests shape `atWarWith`, `invadableNw`, `invadableOw`, and
/// `oldWorldProvincesOwned` to exercise specific priority arms and the
/// structural OW suppression.
AIWorldSnapshot buildColonialPhaseSnapshot({
  required List<String> atWarWith,
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
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
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
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
