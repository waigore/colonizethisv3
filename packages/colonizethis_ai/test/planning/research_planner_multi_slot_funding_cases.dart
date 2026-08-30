// Case bodies for `research_planner_multi_slot_test.dart` (Refs #4310 Slice D).
// Multi-slot funding tier packing and affordability pins.

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
  });
}
