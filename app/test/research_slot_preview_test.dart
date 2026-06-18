// Unit tests for the GAME40001 research slot turn-preview helper (Refs #3512).
//
// Verifies `computeResearchSlotTurnPreview` mirrors the research-phase resolver
// rules (funding RP/treasury rates, the +20% industrial bonus, and the debt
// floor) and derives the dual-segment progress-bar fractions.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show researchPointsMedium;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/utils/research_slot_preview.dart';

Player _player({
  int treasury = 0,
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: 'p1',
    displayName: 'Tester',
    isHuman: true,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

TechDefinition _tech({
  String id = 't1',
  String category = 'civic',
  int cost = 1000,
}) {
  return TechDefinition(id: id, era: 1, category: category, cost: cost);
}

void main() {
  group('computeResearchSlotTurnPreview', () {
    test('positive: None funding has no spend and no anticipated RP', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(treasury: 10000),
        tech: _tech(),
        committedProgress: 100,
        funding: ResearchFundingLevel.none,
      );

      expect(preview.isNoneFunding, isTrue);
      expect(preview.baseRpPerTurn, 0);
      expect(preview.anticipatedRpPerTurn, 0);
      expect(preview.goldCostPerTurn, 0);
      expect(preview.goldSpentThisTurn, 0);
      expect(preview.debtBlocked, isFalse);
      expect(preview.showsAnticipatedSegment, isFalse);
    });

    test('positive: Medium funding with ample treasury applies full RP/gold', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(treasury: 10000),
        tech: _tech(cost: 1800),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.baseRpPerTurn, researchPointsMedium);
      expect(preview.industrialBonusRpPerTurn, 0);
      expect(preview.hasIndustrialBonus, isFalse);
      expect(preview.anticipatedRpPerTurn, researchPointsMedium);
      expect(preview.effectiveRpPerTurn, researchPointsMedium);
      expect(preview.goldCostPerTurn, researchTreasuryCostMedium);
      expect(preview.goldSpentThisTurn, researchTreasuryCostMedium);
      expect(preview.debtBlocked, isFalse);
      expect(preview.showsAnticipatedSegment, isTrue);
    });

    test(
        'negative: spend below the debt floor blocks RP/gold but keeps the cost',
        () {
      // No money_lending => max debt 0; treasury 0 - 150 = -150 < 0.
      final preview = computeResearchSlotTurnPreview(
        player: _player(treasury: 0),
        tech: _tech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.debtBlocked, isTrue);
      expect(preview.anticipatedRpPerTurn, 0);
      expect(preview.goldSpentThisTurn, 0);
      // The per-turn cost and the effective RP are still surfaced for the
      // breakdown dialog even though nothing is applied.
      expect(preview.goldCostPerTurn, researchTreasuryCostMedium);
      expect(preview.effectiveRpPerTurn, researchPointsMedium);
      expect(preview.showsAnticipatedSegment, isFalse);
    });

    test('positive: banking raises the debt floor so the spend is allowed', () {
      // banking => max debt 1000; treasury 0 - 150 = -150 >= -1000.
      final preview = computeResearchSlotTurnPreview(
        player: _player(
          treasury: 0,
          techUnlocked: const {
            kTechIdMoneyLending: true,
            kTechIdBanking: true,
          },
        ),
        tech: _tech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.debtBlocked, isFalse);
      expect(preview.anticipatedRpPerTurn, researchPointsMedium);
      expect(preview.goldSpentThisTurn, researchTreasuryCostMedium);
    });

    test(
        'positive: industrial funding adds +20% RP for a military tech', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(
          treasury: 10000,
          techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
        ),
        tech: _tech(category: 'military'),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.baseRpPerTurn, researchPointsMedium);
      expect(preview.hasIndustrialBonus, isTrue);
      expect(
        preview.industrialBonusRpPerTurn,
        (researchPointsMedium * 1.2).floor() - researchPointsMedium,
      );
      expect(
        preview.effectiveRpPerTurn,
        (researchPointsMedium * 1.2).floor(),
      );
      expect(
        preview.anticipatedRpPerTurn,
        (researchPointsMedium * 1.2).floor(),
      );
    });

    test('negative: industrial bonus does not apply to non-military tech', () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(
          treasury: 10000,
          techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
        ),
        tech: _tech(category: 'civic'),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.hasIndustrialBonus, isFalse);
      expect(preview.industrialBonusRpPerTurn, 0);
      expect(preview.effectiveRpPerTurn, researchPointsMedium);
    });

    test('positive: progress fractions derive from committed + anticipated RP',
        () {
      final preview = computeResearchSlotTurnPreview(
        player: _player(treasury: 10000),
        tech: _tech(cost: 1000),
        committedProgress: 400,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.committedFraction, closeTo(0.4, 1e-9));
      expect(preview.anticipatedFraction, closeTo(0.3, 1e-9));
    });

    test('positive: anticipated fraction is capped to the remaining bar width',
        () {
      // committed 900/1000 leaves 100 RP of headroom; Medium adds 300 RP, so
      // the anticipated segment must clamp to 0.1 (not overflow past 100%).
      final preview = computeResearchSlotTurnPreview(
        player: _player(treasury: 10000),
        tech: _tech(cost: 1000),
        committedProgress: 900,
        funding: ResearchFundingLevel.medium,
      );

      expect(preview.committedFraction, closeTo(0.9, 1e-9));
      expect(preview.anticipatedFraction, closeTo(0.1, 1e-9));
      expect(
        preview.committedFraction + preview.anticipatedFraction,
        lessThanOrEqualTo(1.0 + 1e-9),
      );
    });
  });
}
