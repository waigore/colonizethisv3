/// Shared Game / snapshot fixtures for EXPAND and DEVELOP planner-set
/// NW-suppression AC pins (Refs #2509 / #3997).
///
/// Owns the specialized scaffolds previously local to
/// `expand_phase_planner_nw_suppression_test.dart` and
/// `develop_phase_planner_nw_suppression_test.dart` so those pins keep
/// only planner-set assertions.
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';

/// Active GP for NW-suppression planner-set pins.
const String kNwSuppressionGp1 = 'gp1';

/// Peer GP for EXPAND / DEVELOP NW-suppression pins.
const String kNwSuppressionGp2 = 'gp2';

/// Third GP for DEVELOP peace multi-peer pins.
const String kNwSuppressionGp3 = 'gp3';

/// Default tribe id for NW leakage temptation.
const String kNwSuppressionTribe1 = 'tribe1';

/// Default minor id for OW frontier / non-GP filter pins.
const String kNwSuppressionMinor1 = 'minor1';

/// Minor-held OW invadable province for EXPAND NW-suppression.
const String kExpandNwSuppressionOwProvMinor = 'oldWorld|m1_a';

/// Tribe-held NW province for EXPAND NW-suppression.
const String kExpandNwSuppressionNwProvTribe = 'newWorld|tribe1_a';

/// Unowned NW province for EXPAND NW-suppression.
const String kExpandNwSuppressionNwProvUnowned = 'newWorld|p_unowned';

/// Active-player OW province for DEVELOP NW-suppression.
const String kDevelopNwSuppressionGp1OwProvinceId = 'oldWorld|gp1_a';

/// Active-player NW province for DEVELOP NW-suppression.
const String kDevelopNwSuppressionGp1NwProvinceId = 'newWorld|gp1_a';

/// Tribe-held NW province for DEVELOP NW-suppression.
const String kDevelopNwSuppressionTribeNwProvinceId = 'newWorld|tribe1_a';

/// Unowned NW province for DEVELOP NW-suppression.
const String kDevelopNwSuppressionUnownedNwProvinceId = 'newWorld|p_unowned';

/// Owned-OW tile (active player can improve) for DEVELOP NW-suppression.
const String kDevelopNwSuppressionOwnedOwTileKey = 'oldWorld|gp1_a|3|3';

/// Owned-NW tile (active player can improve) for DEVELOP NW-suppression.
const String kDevelopNwSuppressionOwnedNwTileKey = 'newWorld|gp1_a|4|4';

/// Tribe-held NW tile (must be rejected) for DEVELOP NW-suppression.
const String kDevelopNwSuppressionTribeNwTileKey = 'newWorld|tribe1_a|2|2';

/// Unowned NW tile (must be rejected) for DEVELOP NW-suppression.
const String kDevelopNwSuppressionUnownedNwTileKey = 'newWorld|p_unowned|1|1';

/// EXPAND planner-set NW-suppression Game: below-quota OW minor frontier
/// plus tribe/unowned NW temptation provinces (Refs #3997).
Game buildExpandPhaseNwSuppressionGame({
  int turnNumber = 50,
  int ownTreasury = 9999,
  int regimentCount = 6,
}) {
  return Game(
    id: 'g-2509-expand-phase-planner-nw-suppression-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: kOldWorldRegionId,
            ownerId: kNwSuppressionGp1,
          ),
          Province(
            id: kExpandNwSuppressionOwProvMinor,
            regionId: kOldWorldRegionId,
            ownerId: kNwSuppressionMinor1,
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: kExpandNwSuppressionNwProvTribe,
            regionId: kNewWorldRegionId,
            ownerId: kNwSuppressionTribe1,
          ),
          Province(
            id: kExpandNwSuppressionNwProvUnowned,
            regionId: kNewWorldRegionId,
          ),
        ],
      ),
      armies: [homeArmyWithRegiments(kNwSuppressionGp1, regimentCount)],
    ),
    players: [
      Player(
        id: kNwSuppressionGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kNwSuppressionGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: kNwSuppressionMinor1, displayName: 'Minor1'),
    ],
    tribes: const [Tribe(id: kNwSuppressionTribe1, displayName: 'Tribe1')],
  );
}

/// EXPAND planner-set NW-suppression snapshot: OW below quota with NW
/// colonial signals populated (Refs #3997).
AIWorldSnapshot buildExpandPhaseNwSuppressionSnapshot({
  int oldWorldProvincesOwned = 8,
  List<String> atWarWith = const [
    kNwSuppressionMinor1,
    kNwSuppressionTribe1,
  ],
}) {
  return AIWorldSnapshot(
    playerId: kNwSuppressionGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: const [kExpandNwSuppressionOwProvMinor],
      adjacentOwnerFactionIdsSorted: const [
        kNwSuppressionMinor1,
        kNwSuppressionTribe1,
      ],
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [
        kExpandNwSuppressionNwProvTribe,
        kExpandNwSuppressionNwProvUnowned,
      ],
      adjacentNewWorldOwnerFactionIdsSorted: [kNwSuppressionTribe1],
      preferredColonialTargetFactionIdsSorted: [kNwSuppressionTribe1],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

export 'phase_planner_nw_suppression_test_support_develop.dart';
