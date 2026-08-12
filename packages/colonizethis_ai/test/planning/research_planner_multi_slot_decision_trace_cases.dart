// Case bodies for `research_planner_multi_slot_test.dart` (Refs #4310 Slice D).
// `runResearchPlannerWithDecision` trace record contract (AC10).

import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/research_planner_multi_slot_test_support.dart';

void registerResearchPlannerMultiSlotDecisionTraceCases() {
  group('runResearchPlannerWithDecision trace record (AC10)', () {
    test('records per-slot funding and unconstrained reason when all slots '
        'fund at the desired tier', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 1000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final decision =
          researchPlannerMultiSlotDecisionFor(game: game, api: api).decision;

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
      final game = researchPlannerMultiSlotGameWith(treasury: 100);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
      ]);

      final decision =
          researchPlannerMultiSlotDecisionFor(game: game, api: api).decision;

      expect(decision, isNotNull);
      expect(decision!.fundingTier, ResearchFundingLevel.low);
      expect(decision.slots.length, 2);
      expect(decision.droppedSlotIndices, isEmpty);
      expect(decision.constraintReason, 'uniformDowngrade');
    });

    test('reports treasuryDrop and the dropped highest-index slot when no '
        'uniform tier fits all slots', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 50);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
      ]);

      final decision =
          researchPlannerMultiSlotDecisionFor(game: game, api: api).decision;

      expect(decision, isNotNull);
      expect(decision!.slots.map((s) => s.slotIndex).toList(), [0]);
      expect(decision.droppedSlotIndices, [1]);
      expect(decision.constraintReason, 'treasuryDrop');
    });

    test('reports atWarCap when the at-war cap bounds the target', () {
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

      final decision = researchPlannerMultiSlotDecisionFor(
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
      final game = researchPlannerMultiSlotGameWith(treasury: 5000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final decision = researchPlannerMultiSlotDecisionFor(
        game: game,
        api: api,
        primaryGoal: StrategicGoal.tech,
        view: researchPlannerMultiSlotViewOwning(game, 5),
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
      final game = researchPlannerMultiSlotGameWith(treasury: 1000);
      final api = researchPlannerMultiSlotApiWith(const []);

      final result = researchPlannerMultiSlotDecisionFor(game: game, api: api);

      expect(result.decision, isNull);
      expect(
        result.orders.researchOrdersByPlayerId[researchPlannerMultiSlotPlayerId],
        anyOf(isNull, isEmpty),
      );
    });

    test('decision JSON exposes the multi-slot trace contract', () {
      final game = researchPlannerMultiSlotGameWith(treasury: 1000);
      final api = researchPlannerMultiSlotApiWith([
        researchPlannerMultiSlotRo(0, 'tech_a'),
        researchPlannerMultiSlotRo(1, 'tech_b'),
        researchPlannerMultiSlotRo(2, 'tech_c'),
      ]);

      final json =
          researchPlannerMultiSlotDecisionFor(game: game, api: api).decision!
              .toJson();

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
