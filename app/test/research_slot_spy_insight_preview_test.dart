// Unit tests for GAME40001 spy-insight slot RP preview (Refs #4457).
// Panel widget pins: research_slot_spy_insight_panel_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show applySpyResearchBoostToPoints, researchPointsMedium;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_preview.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_spy_insight.dart';

import 'research_slot_spy_insight_preview_support.dart';

void main() {
  suppressLogsForTests();

  group('computeResearchSlotTurnPreview spy insight', () {
    test('positive: one rival applies +15% after industrial base', () {
      final preview = computeResearchSlotTurnPreview(
        player: spyInsightPreviewPlayer(),
        tech: spyInsightPreviewTech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );

      final expected = applySpyResearchBoostToPoints(
        basePoints: researchPointsMedium,
        qualifyingRivalGpCount: 1,
      );
      expect(preview.anticipatedRpPerTurn, expected);
      expect(preview.spyInsightRpPerTurn, expected - researchPointsMedium);
      expect(preview.hasSpyInsight, isTrue);
      expect(preview.spyInsightRivalNames, ['France']);
    });

    test('positive: two rivals stack to ×1.30', () {
      final preview = computeResearchSlotTurnPreview(
        player: spyInsightPreviewPlayer(),
        tech: spyInsightPreviewTech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 2,
        qualifyingRivalDisplayNames: const ['France', 'Spain'],
      );

      final expected = applySpyResearchBoostToPoints(
        basePoints: researchPointsMedium,
        qualifyingRivalGpCount: 2,
      );
      expect(preview.anticipatedRpPerTurn, expected);
      expect(expected, researchPointsMedium * 13 ~/ 10);
      expect(preview.spyInsightRivalNames, ['France', 'Spain']);
    });

    test('positive: spy insight applies after the industrial bonus', () {
      final preview = computeResearchSlotTurnPreview(
        player: spyInsightPreviewPlayer(
          techUnlocked: const {kTechIdIndustrialFundingOfResearch: true},
        ),
        tech: const TechDefinition(
          id: 'military_t',
          era: 1,
          category: 'military',
          cost: 1800,
        ),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );
      final industrialAdjusted = (researchPointsMedium * 1.2).floor();
      expect(
        preview.anticipatedRpPerTurn,
        applySpyResearchBoostToPoints(
          basePoints: industrialAdjusted,
          qualifyingRivalGpCount: 1,
        ),
      );
    });

    test('negative: funding None keeps 0 RP and no spy row fields', () {
      final preview = computeResearchSlotTurnPreview(
        player: spyInsightPreviewPlayer(),
        tech: spyInsightPreviewTech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.none,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );

      expect(preview.anticipatedRpPerTurn, 0);
      expect(preview.hasSpyInsight, isFalse);
      expect(preview.spyInsightRivalNames, isEmpty);
    });

    test('negative: debt-blocked slot keeps 0 RP and no spy row fields', () {
      final preview = computeResearchSlotTurnPreview(
        player: spyInsightPreviewPlayer(treasury: 0),
        tech: spyInsightPreviewTech(),
        committedProgress: 0,
        funding: ResearchFundingLevel.medium,
        qualifyingRivalGpCount: 1,
        qualifyingRivalDisplayNames: const ['France'],
      );

      expect(preview.debtBlocked, isTrue);
      expect(preview.anticipatedRpPerTurn, 0);
      expect(preview.hasSpyInsight, isFalse);
    });

    test('negative: sequential-blocked later slot omits spy insight', () {
      final sequential = computeResearchSlotsTurnPreview(
        player: spyInsightPreviewPlayer(treasury: 200),
        occupiedSlots: [
          ResearchSlotPreviewInput(
            slotIndex: 0,
            tech: spyInsightPreviewTech(),
            committedProgress: 0,
            funding: ResearchFundingLevel.medium,
            qualifyingRivalGpCount: 1,
            qualifyingRivalDisplayNames: const ['France'],
          ),
          ResearchSlotPreviewInput(
            slotIndex: 1,
            tech: spyInsightPreviewTech(),
            committedProgress: 0,
            funding: ResearchFundingLevel.medium,
            qualifyingRivalGpCount: 1,
            qualifyingRivalDisplayNames: const ['France'],
          ),
        ],
      );

      expect(sequential.bySlotIndex[0]!.hasSpyInsight, isTrue);
      expect(sequential.bySlotIndex[1]!.sequentialBlocked, isTrue);
      expect(sequential.bySlotIndex[1]!.anticipatedRpPerTurn, 0);
      expect(sequential.bySlotIndex[1]!.hasSpyInsight, isFalse);
      expect(
        sequential.totalRp,
        sequential.bySlotIndex[0]!.anticipatedRpPerTurn,
      );
    });
  });

  group('spyInsightForResearchPreview', () {
    test('positive: names the rival court that unlocked the tech', () {
      final game = spyInsightPreviewGame(rivalCount: 1);
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: 'gp1',
        techId: kSpyInsightPreviewTechId,
      );
      expect(insight.count, 1);
      expect(insight.names, ['France']);
    });

    test('positive: two rivals both named', () {
      final game = spyInsightPreviewGame(rivalCount: 2);
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: 'gp1',
        techId: kSpyInsightPreviewTechId,
      );
      expect(insight.count, 2);
      expect(insight.names, ['France', 'Spain']);
    });

    test('negative: spy in a court that has not unlocked the tech', () {
      final game = spyInsightPreviewGame(rivalCount: 1, rivalUnlocked: false);
      final insight = spyInsightForResearchPreview(
        game: game,
        playerId: 'gp1',
        techId: kSpyInsightPreviewTechId,
      );
      expect(insight.count, 0);
      expect(insight.names, isEmpty);
    });
  });
}
