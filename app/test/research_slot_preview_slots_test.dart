// Unit tests for computeResearchSlotsTurnPreview (Refs #3512 / #4720 Slice F).
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show researchPointsMedium;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';

Player _player({int treasury = 0, Map<String, bool>? techUnlocked}) {
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
  suppressLogsForTests();

  group('computeResearchSlotsTurnPreview', () {
    test(
      'positive: sequential walk blocks later slot when treasury exhausted',
      () {
        final tech = _tech();
        final preview = computeResearchSlotsTurnPreview(
          player: _player(treasury: 200),
          occupiedSlots: [
            ResearchSlotPreviewInput(
              slotIndex: 0,
              tech: tech,
              committedProgress: 0,
              funding: ResearchFundingLevel.medium,
            ),
            ResearchSlotPreviewInput(
              slotIndex: 1,
              tech: tech,
              committedProgress: 0,
              funding: ResearchFundingLevel.medium,
            ),
          ],
        );

        expect(
          preview.bySlotIndex[0]!.goldSpentThisTurn,
          researchTreasuryCostMedium,
        );
        expect(
          preview.bySlotIndex[0]!.anticipatedRpPerTurn,
          researchPointsMedium,
        );
        expect(preview.bySlotIndex[0]!.sequentialBlocked, isFalse);

        expect(preview.bySlotIndex[1]!.goldSpentThisTurn, 0);
        expect(preview.bySlotIndex[1]!.anticipatedRpPerTurn, 0);
        expect(preview.bySlotIndex[1]!.debtBlocked, isTrue);
        expect(preview.bySlotIndex[1]!.sequentialBlocked, isTrue);

        expect(preview.totalGoldSpent, researchTreasuryCostMedium);
        expect(preview.totalRp, researchPointsMedium);
        expect(preview.hasSpend, isTrue);
      },
    );

    test('positive: ample treasury sums all slot spends in header totals', () {
      final tech = _tech();
      final preview = computeResearchSlotsTurnPreview(
        player: _player(treasury: 8000),
        occupiedSlots: [
          ResearchSlotPreviewInput(
            slotIndex: 0,
            tech: tech,
            committedProgress: 0,
            funding: ResearchFundingLevel.medium,
          ),
          ResearchSlotPreviewInput(
            slotIndex: 1,
            tech: tech,
            committedProgress: 0,
            funding: ResearchFundingLevel.low,
          ),
        ],
      );

      final slot0 = preview.bySlotIndex[0]!;
      final slot1 = preview.bySlotIndex[1]!;
      expect(
        preview.totalGoldSpent,
        slot0.goldSpentThisTurn + slot1.goldSpentThisTurn,
      );
      expect(
        preview.totalRp,
        slot0.anticipatedRpPerTurn + slot1.anticipatedRpPerTurn,
      );
    });

    test(
      'negative: independent single-slot preview over-estimates later slots',
      () {
        final tech = _tech();
        final independentSlot1 = computeResearchSlotTurnPreview(
          player: _player(treasury: 200),
          tech: tech,
          committedProgress: 0,
          funding: ResearchFundingLevel.medium,
        );
        final sequential = computeResearchSlotsTurnPreview(
          player: _player(treasury: 200),
          occupiedSlots: [
            ResearchSlotPreviewInput(
              slotIndex: 0,
              tech: tech,
              committedProgress: 0,
              funding: ResearchFundingLevel.medium,
            ),
            ResearchSlotPreviewInput(
              slotIndex: 1,
              tech: tech,
              committedProgress: 0,
              funding: ResearchFundingLevel.medium,
            ),
          ],
        );

        expect(independentSlot1.anticipatedRpPerTurn, researchPointsMedium);
        expect(sequential.bySlotIndex[1]!.anticipatedRpPerTurn, 0);
      },
    );

    test('positive: empty occupied list yields no spend summary', () {
      final preview = computeResearchSlotsTurnPreview(
        player: _player(treasury: 500),
        occupiedSlots: const [],
      );

      expect(preview.hasSpend, isFalse);
      expect(preview.totalGoldSpent, 0);
      expect(preview.totalRp, 0);
    });
  });
}
