/// DEVELOP NW-suppression fixtures (Refs #2509 / #4602 Slice E).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';
import 'phase_planner_nw_suppression_test_support.dart';

/// DEVELOP planner-set NW-suppression Game: owned OW+NW tiles plus
/// tribe/unowned NW resource temptation (Refs #3997).
Game buildDevelopPhaseNwSuppressionGame({int turnNumber = 145}) {
  return Game(
    id: 'g-2509-develop-phase-planner-nw-suppression-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kDevelopNwSuppressionGp1OwProvinceId,
            regionId: kOldWorldRegionId,
            ownerId: kNwSuppressionGp1,
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: kNwSuppressionGp1,
            locationProvinceId: kDevelopNwSuppressionGp1OwProvinceId,
            tileKey: '${kDevelopNwSuppressionGp1OwProvinceId}|9|9',
          ),
          Unit(
            id: 'b2',
            type: kUnitTypeBuilder,
            ownerId: kNwSuppressionGp1,
            locationProvinceId: kDevelopNwSuppressionGp1OwProvinceId,
            tileKey: '${kDevelopNwSuppressionGp1OwProvinceId}|8|8',
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: kDevelopNwSuppressionGp1NwProvinceId,
            regionId: kNewWorldRegionId,
            ownerId: kNwSuppressionGp1,
          ),
          Province(
            id: kDevelopNwSuppressionTribeNwProvinceId,
            regionId: kNewWorldRegionId,
            ownerId: kNwSuppressionTribe1,
          ),
          Province(
            id: kDevelopNwSuppressionUnownedNwProvinceId,
            regionId: kNewWorldRegionId,
          ),
        ],
        units: [
          Unit(
            id: 'b3',
            type: kUnitTypeBuilder,
            ownerId: kNwSuppressionGp1,
            locationProvinceId: kDevelopNwSuppressionGp1NwProvinceId,
            tileKey: '${kDevelopNwSuppressionGp1NwProvinceId}|7|7',
          ),
        ],
      ),
      resourceByTileKey: const {
        kDevelopNwSuppressionOwnedOwTileKey: 'grain',
        kDevelopNwSuppressionOwnedNwTileKey: 'tobacco',
        kDevelopNwSuppressionTribeNwTileKey: 'spices',
        kDevelopNwSuppressionUnownedNwTileKey: 'gold',
      },
    ),
    players: const [
      Player(id: kNwSuppressionGp1, displayName: 'GP1', isHuman: false),
      Player(id: kNwSuppressionGp2, displayName: 'GP2', isHuman: false),
      Player(id: kNwSuppressionGp3, displayName: 'GP3', isHuman: false),
    ],
    tribes: const [Tribe(id: kNwSuppressionTribe1, displayName: 'Tribe1')],
    minorNations: const [
      MinorNation(id: kNwSuppressionMinor1, displayName: 'Minor1'),
    ],
  );
}

/// DEVELOP planner-set NW-suppression snapshot: OW at quota with NW
/// colonial signals and multi-faction `atWarWith` (Refs #3997).
AIWorldSnapshot buildDevelopPhaseNwSuppressionSnapshot({
  List<String> atWarWith = const [
    kNwSuppressionGp2,
    kNwSuppressionGp3,
    kNwSuppressionTribe1,
    kNwSuppressionMinor1,
  ],
}) {
  return AIWorldSnapshot(
    playerId: kNwSuppressionGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
    ),
    colonial: const ColonialSummary(
      newWorldProvincesOwned: 1,
      invadableNewWorldProvinceIdsSorted: [
        kDevelopNwSuppressionTribeNwProvinceId,
        kDevelopNwSuppressionUnownedNwProvinceId,
      ],
      adjacentNewWorldOwnerFactionIdsSorted: [kNwSuppressionTribe1],
      preferredColonialTargetFactionIdsSorted: [kNwSuppressionTribe1],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}
