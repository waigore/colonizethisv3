import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'diplomacy_planner_below_quota_peace_stalled_targets_cases_tail_cases.dart';


// Stalled / integration below-quota peace cases (former part3 shard, Refs #3941).
void registerDiplomacyBelowQuotaPeaceStalledTargetsCases() {
  test(
    'stalledZeroRegimentAllFactionPeaceTargets includes minors when stalled',
    () {
      final game = Game(
        id: 'g-zero-reg-all-faction-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M1'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['minor1', 'minor2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|m1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledZeroRegimentAllFactionPeaceTargets(game: game, snapshot: snapshot),
        ['minor1', 'minor2'],
        reason: 'Zero-regiment path peaces minors/tribes only, not Great Powers',
      );
    },
  );

  test(
    'belowQuotaMultiMinorDistractionPeaceTargets keeps focused minor only',
    () {
      final game = Game(
        id: 'g-multi-minor-focus',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 9; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              Province(
                id: 'oldWorld|m1_a',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              Province(
                id: 'oldWorld|m2_a',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: homeArmyIdFor('gp3'),
              ownerId: 'gp3',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|gp3_0',
              regimentUnitIds: const ['u_gp3_1', 'u_gp3_2'],
              isHomeArmy: true,
            ),
          ],
        ),
        players: const [
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M1'),
          MinorNation(id: 'minor2', displayName: 'M2'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'minor2',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['minor1', 'minor2']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|m1_a', 'oldWorld|m2_a'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        ),
        ['minor2'],
      );
    },
  );

  test(
    'stalledZeroRegimentGpPeaceTargets includes all GP wars when stalled',
    () {
      final game = Game(
        id: 'g-zero-reg-gp-peace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 8; i++)
                Province(
                  id: 'oldWorld|gp3_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
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
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp3',
            factionId2: 'gp4',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp3',
        threats: ThreatSummary(atWarWith: ['gp4', 'minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|inv1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
        ['gp4'],
      );
    },
  );


  registerDiplomacyBelowQuotaPeaceStalledTargetsCasesTail();
}
