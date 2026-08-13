// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

void registerExpandPhasePlannerPeerPeaceWarFocusCasesPartA() {
  group('nearQuotaHoldPeaceTargets', () {
    test('peaces non-blocker GP wars when stalled at 8 OW', () {
      final game = Game(
        id: 'g-near-quota-hold',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 0; i < 10; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|frontier',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 20,
          ),
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp5',
            state: RelationState.atWar,
            score: 20,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4', 'gp5']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|frontier'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
        contains('gp5'),
      );
    });
  });

  group('criticalOwHoldPeaceTargets', () {
    test('includes GP wars at exactly six OW provinces', () {
      final game = Game(
        id: 'g-critical-ow-hold',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 6; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              for (var i = 0; i < 12; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
          Player(id: 'gp4', displayName: 'P4', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['gp3']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 6),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(criticalOwHoldPeaceTargets(game: game, snapshot: snapshot), [
        'gp3',
      ]);
    });
  });

  group('belowQuotaActiveMinorWarTarget', () {
    test('returns at-war minor owning invadable provinces', () {
      final game = Game(
        id: 'g-active-minor',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp4',
              ),
              const Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp4', displayName: 'P4', isHuman: false)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp4',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(atWarWith: ['minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|p2'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
        'minor1',
      );
    });
  });

  group('greatPowerWarCountOnTarget', () {
    test('counts GPs at war via diplomacy relations', () {
      final game = Game(
        id: 'g-gp-war-count',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 20,
          ),
        ],
      );
      expect(greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'), 2);
    });

  });
}
