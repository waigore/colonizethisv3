import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_ai/src/planning/research_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

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

  /// Player view owning [ownedOldWorldProvinces] Old World provinces, used to
  /// drive the stalled-expansion cap (`isStalledOldWorldExpansion`): 1..9 owned
  /// is stalled, 0 owned is terminal collapse (not stalled). Refs #3472.
  PlayerView viewOwning(Game game, int ownedOldWorldProvinces) {
    final provincesById = <String, Province>{};
    for (var i = 0; i < ownedOldWorldProvinces; i++) {
      final id = ProvinceId.full(kOldWorldRegionId, 'p$i');
      provincesById[id] = Province(
        id: id,
        regionId: kOldWorldRegionId,
        ownerId: playerId,
      );
    }
    return PlayerView(
      playerId: playerId,
      player: game.players.single,
      ownUnitsById: const {},
      provincesById: provincesById,
      visibilityByTile: const {},
      prospectedTiles: const {},
      diplomacyByOtherId: const {},
    );
  }

  List<ResearchOrder> runFor({
    required Game game,
    required FakeOrderSuggestionAPIForDomainPlannerTests api,
    StrategicGoal primaryGoal = StrategicGoal.expand,
    AIConfig config = kTestAiConfig,
    PlayerView? view,
  }) {
    final ctx = buildTestPlannerContext(
      game: game,
      topology: topology,
      primaryGoal: primaryGoal,
      config: config,
      suggestionAPI: api,
      view: view,
    );
    final orders = runResearchPlanner(ctx: ctx);
    return orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
  }

  ResearchPlannerResult decisionFor({
    required Game game,
    required FakeOrderSuggestionAPIForDomainPlannerTests api,
    StrategicGoal primaryGoal = StrategicGoal.expand,
    AIConfig config = kTestAiConfig,
    PlayerView? view,
  }) {
    final ctx = buildTestPlannerContext(
      game: game,
      topology: topology,
      primaryGoal: primaryGoal,
      config: config,
      suggestionAPI: api,
      view: view,
    );
    return runResearchPlannerWithDecision(ctx: ctx);
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

    test('caps new slot fill at kResearchSlotFillCapWhenStalledExpansion when '
        'Old World expansion is stalled even when primaryGoal is tech', () {
      final game = gameWith(treasury: 5000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final result = runFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        // 5 owned Old World provinces => stalled (1..9 band).
        view: viewOwning(game, 5),
      );

      expect(
        result.length,
        kResearchSlotFillCapWhenStalledExpansion,
        reason: 'stalled-expansion cap limits new assignments to 1',
      );
    });

    test('does not apply the stalled-expansion cap with zero Old World '
        'provinces (terminal collapse, not stalled)', () {
      final game = gameWith(treasury: 5000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final result = runFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        // 0 owned => isStalledOldWorldExpansion is false (requires > 0).
        view: viewOwning(game, 0),
      );

      expect(
        result.length,
        3,
        reason: 'zero Old World holdings is not the stalled band',
      );
    });

    test('stalled-expansion cap binds below the at-war cap when both fire', () {
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
        view: viewOwning(game, 5),
      );

      expect(
        result.length,
        kResearchSlotFillCapWhenStalledExpansion,
        reason: 'the smaller (stalled) cap wins over the at-war cap',
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

  group('runResearchPlannerWithDecision trace record (AC10)', () {
    test('records per-slot funding and unconstrained reason when all slots '
        'fund at the desired tier', () {
      final game = gameWith(treasury: 1000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final decision = decisionFor(game: game, api: api).decision;

      expect(decision, isNotNull);
      expect(decision!.emptySlotCount, 3);
      expect(decision.targetSlotCount, 3);
      expect(decision.atWarCapApplied, isFalse);
      expect(decision.fundingTier, ResearchFundingLevel.medium);
      expect(decision.slots.map((s) => s.slotIndex).toList(), [0, 1, 2]);
      expect(decision.slots.map((s) => s.techId).toSet(), {
        'tech_a',
        'tech_b',
        'tech_c',
      });
      expect(
        decision.slots.every((s) => s.funding == ResearchFundingLevel.medium),
        isTrue,
      );
      expect(decision.droppedSlotIndices, isEmpty);
      expect(decision.constraintReason, 'none');
    });

    test('reports uniformDowngrade when treasury forces a lower tier with no '
        'slot dropped', () {
      final game = gameWith(treasury: 100);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b')]);

      final decision = decisionFor(game: game, api: api).decision;

      expect(decision, isNotNull);
      expect(decision!.fundingTier, ResearchFundingLevel.low);
      expect(decision.slots.length, 2);
      expect(decision.droppedSlotIndices, isEmpty);
      expect(decision.constraintReason, 'uniformDowngrade');
    });

    test('reports treasuryDrop and the dropped highest-index slot when no '
        'uniform tier fits all slots', () {
      final game = gameWith(treasury: 50);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b')]);

      final decision = decisionFor(game: game, api: api).decision;

      expect(decision, isNotNull);
      expect(decision!.slots.map((s) => s.slotIndex).toList(), [0]);
      expect(decision.droppedSlotIndices, [1]);
      expect(decision.constraintReason, 'treasuryDrop');
    });

    test('reports atWarCap when the at-war cap bounds the target', () {
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

      final decision = decisionFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
      ).decision;

      expect(decision, isNotNull);
      expect(decision!.emptySlotCount, 3);
      expect(decision.targetSlotCount, kResearchSlotFillCapWhenAtWar);
      expect(decision.atWarCapApplied, isTrue);
      expect(decision.slots.length, kResearchSlotFillCapWhenAtWar);
      expect(decision.droppedSlotIndices, isEmpty);
      expect(decision.constraintReason, 'atWarCap');
    });

    test('reports stalledExpansionCap and the cap target when Old World '
        'expansion is stalled', () {
      final game = gameWith(treasury: 5000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final decision = decisionFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        view: viewOwning(game, 5),
      ).decision;

      expect(decision, isNotNull);
      expect(decision!.emptySlotCount, 3);
      expect(
        decision.targetSlotCount,
        kResearchSlotFillCapWhenStalledExpansion,
      );
      expect(decision.stalledExpansionCapApplied, isTrue);
      expect(decision.atWarCapApplied, isFalse);
      expect(decision.slots.length, kResearchSlotFillCapWhenStalledExpansion);
      expect(decision.droppedSlotIndices, isEmpty);
      expect(decision.constraintReason, 'stalledExpansionCap');
    });

    test('decision is null when the planner emits no research orders', () {
      final game = gameWith(treasury: 1000);
      final api = apiWith(const []);

      final result = decisionFor(game: game, api: api);

      expect(result.decision, isNull);
      expect(
        result.orders.researchOrdersByPlayerId[playerId],
        anyOf(isNull, isEmpty),
      );
    });

    test('decision JSON exposes the multi-slot trace contract', () {
      final game = gameWith(treasury: 1000);
      final api = apiWith([ro(0, 'tech_a'), ro(1, 'tech_b'), ro(2, 'tech_c')]);

      final json = decisionFor(game: game, api: api).decision!.toJson();

      expect(json['emptySlotCount'], 3);
      expect(json['targetSlotCount'], 3);
      expect(json['atWarCapApplied'], isFalse);
      expect(json['stalledExpansionCapApplied'], isFalse);
      expect(json['fundingTier'], 'medium');
      expect(json['constraintReason'], 'none');
      expect(json['droppedSlotIndices'], isEmpty);
      final slots = json['slots'] as List<Object?>;
      expect(slots.length, 3);
      final first = slots.first as Map<String, Object?>;
      expect(first['slotIndex'], 0);
      expect(first['techId'], 'tech_a');
      expect(first['funding'], 'medium');
    });
  });
}
