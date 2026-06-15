import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_ai/src/planning/research_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

/// Treasury-aware multi-slot funding for the Full-AI research planner
/// (Refs #3472). Uses a fake suggestion API so the funding/packing/preserve
/// behavior is exercised deterministically.
/// SPEC/ai/ai-architecture.md § Research.
void main() {
  const playerId = 'gp1';
  const topology = MapTopology(nodes: [], edges: []);

  Game gameWith({
    required int treasury,
    Map<String, int>? progress,
    int researchSlots = 3,
  }) => Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        leaderKey: 'victoria',
        treasury: treasury,
        researchSlots: researchSlots,
        researchProgressByTechId: progress,
      ),
    ],
  );

  FakeOrderSuggestionAPIForDomainPlannerTests apiWith(
    List<ResearchOrder> research,
  ) => FakeOrderSuggestionAPIForDomainPlannerTests(
    work: const [],
    build: const [],
    move: const [],
    research: research,
    navalMove: const [],
    navalMission: const [],
  );

  ResearchOrder ro(int slot, String tech) => ResearchOrder(
    slotIndex: slot,
    techId: tech,
    funding: ResearchFundingLevel.medium,
  );

  List<ResearchOrder> runFor({
    required Game game,
    required FakeOrderSuggestionAPIForDomainPlannerTests api,
    StrategicGoal primaryGoal = StrategicGoal.expand,
    AIConfig config = kTestAiConfig,
  }) {
    final ctx = buildTestPlannerContext(
      game: game,
      topology: topology,
      primaryGoal: primaryGoal,
      config: config,
      suggestionAPI: api,
    );
    final orders = runResearchPlanner(ctx: ctx);
    return orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
  }

  group('runResearchPlanner multi-slot funding', () {
    test('fills all empty slots with a uniform affordable tier', () {
      final game = gameWith(treasury: 1000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final result = runFor(game: game, api: api);

      expect(result.length, 3, reason: 'all three empty slots filled');
      expect(
        result.map((o) => o.techId).toSet(),
        {'tech_a', 'tech_b', 'tech_c'},
        reason: 'distinct techs preserved from suggestions',
      );
      expect(
        result.map((o) => o.funding).toSet(),
        {ResearchFundingLevel.medium},
        reason: 'uniform balanced tier at default funding aggression',
      );
    });

    test('primaryGoal tech fills all slots at the High funding floor', () {
      final game = gameWith(treasury: 5000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final result = runFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
      );

      expect(result.length, 3);
      expect(
        result.every((o) => o.funding == ResearchFundingLevel.high),
        isTrue,
        reason: 'primaryGoal==tech applies the High funding floor',
      );
    });

    test('downgrades uniformly to Low when a higher tier is unaffordable', () {
      // treasury 100, two slots: Low (50*2=100) fits at floor 0; Medium does not.
      final game = gameWith(treasury: 100);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b')]);

      final result = runFor(game: game, api: api);

      expect(result.length, 2);
      expect(
        result.every((o) => o.funding == ResearchFundingLevel.low),
        isTrue,
        reason: 'uniform step-down keeps both slots at Low',
      );
    });

    test('drops the highest-index new slot when no uniform tier fits both', () {
      // treasury 50: two at Low (100) exceeds floor; one at Low (50) fits.
      final game = gameWith(treasury: 50);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b')]);

      final result = runFor(game: game, api: api);

      expect(result.length, 1, reason: 'highest-index new slot dropped');
      expect(result.single.slotIndex, 0);
      expect(result.single.funding, ResearchFundingLevel.low);
    });

    test('preserves in-progress research at None when broke', () {
      final game = gameWith(treasury: 0, progress: {'tech_ip': 25});
      // Suggestion layer re-emits the in-progress tech in slot 0.
      final api = apiWith([ro(0, 'tech_ip')]);

      final result = runFor(game: game, api: api);

      expect(result.length, 1, reason: 'in-progress research is never dropped');
      expect(result.single.techId, 'tech_ip');
      expect(
        result.single.funding,
        ResearchFundingLevel.none,
        reason: 'broke treasury keeps progress without spending',
      );
    });

    test('caps new slot fill at kResearchSlotFillCapWhenAtWar while at war '
        'even when primaryGoal is tech (AC7)', () {
      final game = gameWith(treasury: 5000).copyWith(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: playerId,
            factionId2: 'enemy',
            state: RelationState.atWar,
          ),
        ],
      );
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final result = runFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
      );

      expect(
        result.length,
        kResearchSlotFillCapWhenAtWar,
        reason: 'at-war cap limits new assignments to 2 despite tech goal',
      );
    });

    test('does not cap slot fill when at peace (negative control for AC7)', () {
      final game = gameWith(treasury: 5000).copyWith(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: playerId,
            factionId2: 'neighbor',
            state: RelationState.atPeace,
          ),
        ],
      );
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final result = runFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
      );

      expect(
        result.length,
        3,
        reason: 'an at-peace relation does not trigger the at-war cap',
      );
    });

    test('emits no new research when research domain weight is far below '
        'threshold', () {
      final game = gameWith(treasury: 1000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);
      const lowResearchConfig = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
        parameterOverrides: {'personalityDomainWeights.research': 10},
      );

      final result = runFor(game: game, api: api, config: lowResearchConfig);

      expect(
        result,
        isEmpty,
        reason: 'non-tech primary goal with weak research scales fill to zero',
      );
    });
  });
}
