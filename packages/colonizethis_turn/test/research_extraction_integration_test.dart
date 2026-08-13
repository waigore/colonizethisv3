import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'research_extraction_integration_cases.dart';
import 'support/turn_resolver_test_harness.dart';

void main() {
  group('Research to extraction cap integration', () {
    final cases = researchExtractionCapIncreaseCases();

    test('contains at least one cap-increase tech case', () {
      expect(cases, isNotEmpty);
    });

    for (final testCase in cases) {
      test(
        '${testCase.techId}: cap ${testCase.beforeCap} -> ${testCase.afterCap} applies next turn',
        () {
          final baseGame = researchExtractionBuildBaseGame(
            initialUnlockedTechs: testCase.prerequisites,
            discoveryResourceId: testCase.discoveryResourceId,
          );

          // Turn A: baseline extraction with pre-research cap.
          final afterBaseline = resolveTurnComplete(
            game: baseGame,
            topology: researchExtractionTopology,
            orders: const Orders(),
            tileMapByRegion: researchExtractionTileMapByRegion,
            defaultAssignments: const [],
          );
          final baselineDelta =
              researchExtractionGrainDelta(baseGame, afterBaseline);
          expect(
            baselineDelta,
            testCase.beforeCap,
            reason:
                'Extraction ignoring baseline cap before researching ${testCase.techId}',
          );

          // Seed progress just below the (rebalanced) cost so a single
          // maximum-funding turn unlocks the tech regardless of its cost tier,
          // keeping this test focused on the cap-applies-next-turn behavior
          // rather than research pacing. SPEC/game/tech-tree.md § Research Model.
          final seededProgress = techById(testCase.techId)!.cost - 1;
          final researchInput = afterBaseline.copyWith(
            players: [
              for (final p in afterBaseline.players)
                p.id == researchExtractionPlayerId
                    ? p.copyWith(
                        researchProgressByTechId: {
                          testCase.techId: seededProgress,
                        },
                      )
                    : p,
            ],
          );

          // Turn B: research resolves this turn; extraction still uses previous cap.
          final withResearch = resolveTurnComplete(
            game: researchInput,
            topology: researchExtractionTopology,
            orders: Orders(
              researchOrdersByPlayerId: {
                researchExtractionPlayerId: [
                  ResearchOrder(
                    slotIndex: 0,
                    techId: testCase.techId,
                    funding: ResearchFundingLevel.maximum,
                  ),
                ],
              },
            ),
            tileMapByRegion: researchExtractionTileMapByRegion,
            defaultAssignments: const [],
          );

          final researchedPlayer =
              withResearch.playerById(researchExtractionPlayerId)!;
          expect(
            researchedPlayer.techUnlocked?[testCase.techId],
            isTrue,
            reason:
                'Cap not updated after research: expected ${testCase.techId} to unlock in research phase',
          );

          // Turn C: extraction must now use the updated cap.
          final afterUpgradeExtraction = resolveTurnComplete(
            game: withResearch,
            topology: researchExtractionTopology,
            orders: const Orders(),
            tileMapByRegion: researchExtractionTileMapByRegion,
            defaultAssignments: const [],
          );
          final postUpgradeDelta = researchExtractionGrainDelta(
            withResearch,
            afterUpgradeExtraction,
          );
          expect(
            postUpgradeDelta,
            testCase.afterCap,
            reason:
                'Extraction ignoring updated cap after ${testCase.techId} was researched',
          );
        },
      );
    }
  });
}
