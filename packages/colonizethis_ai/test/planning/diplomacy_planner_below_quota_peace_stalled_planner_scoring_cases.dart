// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';
import 'diplomacy_planner_below_quota_peace_stalled_planner_scoring_cases_tail_cases.dart';


void registerDiplomacyBelowQuotaPeaceStalledPlannerScoringCases() {
  test(
    'defaultStartOwMinorDeclareTarget picks uninvaded minor on GP-only invadable frontier',
    () {
      final game = Game(
        id: 'g-default-start-minor-gp-frontier',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 7; i++)
                Province(
                  id: 'oldWorld|gp4_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
              const Province(
                id: 'oldWorld|minor2',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
              const Province(
                id: 'oldWorld|gp3_block',
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
        minorNations: const [MinorNation(id: 'minor2', displayName: 'M2')],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp4',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|gp3_block'],
          adjacentOwnerFactionIdsSorted: ['gp3'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        defaultStartOwMinorDeclareTarget(game: game, snapshot: snapshot),
        'minor2',
      );
    },
  );

  test(
    'runDiplomacyPlannerWithResult scoring path prefers minor over GP blocker on GP-only frontier',
    () {
      final game = Game(
        id: 'g-scoring-minor-before-gp',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              for (var i = 1; i <= 9; i++)
                Province(
                  id: 'oldWorld|gp6_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              const Province(
                id: 'oldWorld|gp6_frontier',
                regionId: 'oldWorld',
                ownerId: 'gp6',
              ),
              const Province(
                id: 'oldWorld|minor1_hold',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
              const Province(
                id: 'oldWorld|minor2_hold',
                regionId: 'oldWorld',
                ownerId: 'minor2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M1'),
          MinorNation(id: 'minor2', displayName: 'M2'),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
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
        threats: ThreatSummary(atWarWith: ['gp6', 'minor1']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          adjacentOwnerFactionIdsSorted: ['gp6'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        nationId: 'gp5',
        primaryGoal: StrategicGoal.conquer,
        suggestionAPI: FakeOrderSuggestionAPIForDomainPlannerTests(
          work: const [],
          build: const [],
          move: const [],
          research: const [],
          navalMove: const [],
          navalMission: const [],
          diplomatic: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor2',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp6',
            ),
          ],
        ),
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.declareWarOnly,
      );
      expect(result.declaredWarTargetFactionId, 'minor2');
    },
  );

  registerDiplomacyBelowQuotaPeaceStalledPlannerScoringCasesTail();
}
