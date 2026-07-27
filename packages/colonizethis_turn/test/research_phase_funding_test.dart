import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_funding_cases.dart';
import 'support/turn_game_fixtures.dart';

void main() {
  group('Research phase funding', () {
    test('accumulates research progress and unlocks tech when cost reached', () {
      final tech = techById(kTechIdCropRotation)!;
      final game = researchPhaseTestBaseGame(
        treasury: 2000,
        techUnlocked: const {},
      );
      final orders = p1ResearchOrders(
        techId: kTechIdCropRotation,
        funding: ResearchFundingLevel.maximum,
      );

      final player = resolveResearchPlayer(game: game, orders: orders);

      expect(player.treasury, lessThan(game.players.single.treasury));
      final progress = player.researchProgressByTechId ?? const {};
      final unlocked = player.techUnlocked ?? const {};

      if (progress.isNotEmpty) {
        expect(progress[kTechIdCropRotation], isNotNull);
        expect(progress[kTechIdCropRotation], lessThan(tech.cost));
        expect(unlocked[kTechIdCropRotation], isNot(true));
      } else {
        expect(unlocked[kTechIdCropRotation], isTrue);
      }
    });

    test('applies prerequisite rule: cannot research tech without prereqs', () {
      final game = researchPhaseTestBaseGame(
        treasury: 2000,
        techUnlocked: const {},
      );
      final orders = p1ResearchOrders(
        techId: kTechIdWindSawMill,
        funding: ResearchFundingLevel.maximum,
      );
      final player = resolveResearchPlayer(game: game, orders: orders);

      expect(player.treasury, game.players.single.treasury);
      expect(player.researchProgressByTechId ?? const {}, isEmpty);
      expect(player.techUnlocked?[kTechIdWindSawMill], isNot(true));
    });

    test(
      'research with funding none does not spend treasury or add progress',
      () {
        final game = researchPhaseTestBaseGame(
          treasury: 100,
          techUnlocked: const {},
        );
        final orders = p1ResearchOrders(
          techId: kTechIdCropRotation,
          funding: ResearchFundingLevel.none,
        );
        final player = resolveResearchPlayer(game: game, orders: orders);

        expect(player.treasury, 100);
        expect(player.researchProgressByTechId ?? const {}, isEmpty);
      },
    );

    test('research with low funding deducts treasury and adds progress', () {
      final game = researchPhaseTestBaseGame(
        treasury: 100,
        techUnlocked: const {kTechIdSawMill: true},
      );
      final orders = p1ResearchOrders(
        techId: kTechIdWindSawMill,
        funding: ResearchFundingLevel.low,
      );
      final player = resolveResearchPlayer(game: game, orders: orders);

      expect(player.treasury, 50);
      expect(
        (player.researchProgressByTechId ?? const {})[kTechIdWindSawMill],
        100,
      );
    });

    test('research with maximum funding has efficiency bonus', () {
      final game = researchPhaseTestBaseGame(
        treasury: 2000,
        techUnlocked: const {},
      );
      final orders = p1ResearchOrders(
        techId: kTechIdCropRotation,
        funding: ResearchFundingLevel.maximum,
      );
      final player = resolveResearchPlayer(game: game, orders: orders);

      expect(player.treasury, 1000);
      expect(player.techUnlocked![kTechIdCropRotation], isTrue);
    });

    test(
      'debt cap rejects allocation that would breach max debt (no money lending)',
      () {
        final game = researchPhaseTestBaseGame(
          treasury: 30,
          techUnlocked: const {kTechIdSawMill: true},
        );
        final orders = p1ResearchOrders(
          techId: kTechIdWindSawMill,
          funding: ResearchFundingLevel.low,
        );
        final player = resolveResearchPlayer(game: game, orders: orders);

        expect(player.treasury, 30);
        expect(player.researchProgressByTechId ?? const {}, isEmpty);
        expect(player.techUnlocked?[kTechIdWindSawMill], isNot(true));
      },
    );

    test(
      'debt cap allows treasury to go negative within money-lending floor',
      () {
        final game = researchPhaseTestBaseGame(
          treasury: 30,
          techUnlocked: const {kTechIdSawMill: true, kTechIdMoneyLending: true},
        );
        final orders = p1ResearchOrders(
          techId: kTechIdWindSawMill,
          funding: ResearchFundingLevel.low,
        );
        final player = resolveResearchPlayer(game: game, orders: orders);

        expect(player.treasury, -20);
        expect(
          (player.researchProgressByTechId ?? const {})[kTechIdWindSawMill],
          100,
        );
      },
    );

    test('all funding levels match spec values via game behavior', () {
      for (final scenario in windSawMillFundingLevelScenarios) {
        final game = researchPhaseTestBaseGame(
          treasury: scenario.treasury,
          techUnlocked: windSawMillPrereqMet,
        );
        final orders = p1ResearchOrders(
          techId: kTechIdWindSawMill,
          funding: scenario.funding,
        );
        final player = resolveResearchPlayer(game: game, orders: orders);

        expect(player.treasury, scenario.expectedTreasury);
        if (scenario.unlocked) {
          expect(player.techUnlocked![kTechIdWindSawMill], isTrue);
        } else {
          expect(
            (player.researchProgressByTechId ??
                const {})[kTechIdWindSawMill],
            scenario.expectedProgress,
          );
          expect(player.techUnlocked?[kTechIdWindSawMill], isNot(true));
        }
      }
    });
  });
}
