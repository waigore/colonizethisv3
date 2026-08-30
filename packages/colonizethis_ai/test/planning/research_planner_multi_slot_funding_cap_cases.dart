// At-war and stalled-expansion slot-fill caps (Refs #4310 Slice D; Refs #4669).

import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/research_planner_multi_slot_test_support.dart';

void registerResearchPlannerMultiSlotFundingCapCases() {
  group('runResearchPlanner multi-slot funding', () {
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
