// Case bodies for `research_planner_multi_slot_test.dart` (Refs #4310 Slice D).
// Multi-slot funding tier packing, caps, and domain-weight suppression.

import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/research_planner_multi_slot_test_support.dart';

void registerResearchPlannerMultiSlotFundingCases() {
  group('runResearchPlanner multi-slot funding', () {
    test('fills all empty slots with a uniform affordable tier', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 1000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(game: game, api: api);

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
      final game = researchPlannerMultiSlotGameWith(treasury: 5000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(
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
      final game = researchPlannerMultiSlotGameWith(treasury: 100);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
      ]);

      final result = researchPlannerMultiSlotRunFor(game: game, api: api);

      expect(result.length, 2);
      expect(
        result.every((o) => o.funding == ResearchFundingLevel.low),
        isTrue,
        reason: 'uniform step-down keeps both slots at Low',
      );
    });

    test('drops the highest-index new slot when no uniform tier fits both', () {
      // treasury 50: two at Low (100) exceeds floor; one at Low (50) fits.
      final game = researchPlannerMultiSlotGameWith(treasury: 50);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
      ]);

      final result = researchPlannerMultiSlotRunFor(game: game, api: api);

      expect(result.length, 1, reason: 'highest-index new slot dropped');
      expect(result.single.slotIndex, 0);
      expect(result.single.funding, ResearchFundingLevel.low);
    });

    test('preserves in-progress research at None when broke', () {
      final game = researchPlannerMultiSlotGameWith(
        treasury: 0,
        progress: {'tech_ip': 25},
      );
      // Suggestion layer re-emits the in-progress tech in slot 0.
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_ip'),
      ]);

      final result = researchPlannerMultiSlotRunFor(game: game, api: api);

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
      final game = researchPlannerMultiSlotGameWith(treasury: 5000).copyWith(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: researchPlannerMultiSlotPlayerId,
            factionId2: 'enemy',
            state: RelationState.atWar,
          ),
        ],
      );
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(
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
      final game = researchPlannerMultiSlotGameWith(treasury: 5000).copyWith(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: researchPlannerMultiSlotPlayerId,
            factionId2: 'neighbor',
            state: RelationState.atPeace,
          ),
        ],
      );
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(
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
      final game = researchPlannerMultiSlotGameWith(treasury: 5000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        // 5 owned Old World provinces => stalled (1..9 band).
        view: researchPlannerMultiSlotViewOwning(game, 5),
      );

      expect(
        result.length,
        kResearchSlotFillCapWhenStalledExpansion,
        reason: 'stalled-expansion cap limits new assignments to 1',
      );
    });

    test('does not apply the stalled-expansion cap with zero Old World '
        'provinces (terminal collapse, not stalled)', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 5000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        // 0 owned => isStalledOldWorldExpansion is false (requires > 0).
        view: researchPlannerMultiSlotViewOwning(game, 0),
      );

      expect(
        result.length,
        3,
        reason: 'zero Old World holdings is not the stalled band',
      );
    });

    test('stalled-expansion cap binds below the at-war cap when both fire', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 5000).copyWith(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: researchPlannerMultiSlotPlayerId,
            factionId2: 'enemy',
            state: RelationState.atWar,
          ),
        ],
      );
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final result = researchPlannerMultiSlotRunFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        view: researchPlannerMultiSlotViewOwning(game, 5),
      );

      expect(
        result.length,
        kResearchSlotFillCapWhenStalledExpansion,
        reason: 'the smaller (stalled) cap wins over the at-war cap',
      );
    });

    test('emits no new research when research domain weight is far below '
        'threshold', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 1000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);
      const lowResearchConfig = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
        parameterOverrides: {'personalityDomainWeights.research': 10},
      );

      final result = researchPlannerMultiSlotRunFor(
        game: game,
        api: api,
        config: lowResearchConfig,
      );

      expect(
        result,
        isEmpty,
        reason: 'non-tech primary goal with weak research scales fill to zero',
      );
    });
  });
}
