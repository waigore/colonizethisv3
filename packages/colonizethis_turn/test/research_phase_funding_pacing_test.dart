import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_test_support.dart';

void main() {
  group('Research pacing at Medium funding (cost rebalance, Refs #3512)', () {
    // Chains [turns] Research phases for a single slot-0 tech at [funding],
    // carrying treasury / progress / unlocks forward each turn.
    Game runResearchTurns({
      required String techId,
      required ResearchFundingLevel funding,
      required int turns,
      required int treasury,
      Map<String, bool>? techUnlocked,
    }) {
      var game = researchPhaseTestBaseGame(
        treasury: treasury,
        techUnlocked: techUnlocked,
      );
      for (var i = 0; i < turns; i++) {
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': [
              ResearchOrder(slotIndex: 0, techId: techId, funding: funding),
            ],
          },
        );
        game = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: const MapTopology(),
            orders: orders,
          ),
        );
      }
      return game;
    }

    test('tier-1 tech (1800 RP) completes in 6 Medium turns, not 5', () {
      // crop_rotation is tier-1 (cost 1800) with no prerequisites.
      final after5 = runResearchTurns(
        techId: kTechIdCropRotation,
        funding: ResearchFundingLevel.medium,
        turns: 5,
        treasury: 3000,
      ).players.single;
      expect(after5.techUnlocked?[kTechIdCropRotation], isNot(true));
      expect(
        (after5.researchProgressByTechId ?? const {})[kTechIdCropRotation],
        1500,
      );

      final after6 = runResearchTurns(
        techId: kTechIdCropRotation,
        funding: ResearchFundingLevel.medium,
        turns: 6,
        treasury: 3000,
      ).players.single;
      expect(after6.techUnlocked?[kTechIdCropRotation], isTrue);
    });

    test('tier-4 tech (3600 RP) completes in 12 Medium turns, not 11', () {
      // safety_lamp is tier-4 (cost 3600); pre-unlock its direct prerequisites.
      const prereqs = {kTechIdLargeCoalMines: true, kTechIdDynamite: true};
      final after11 = runResearchTurns(
        techId: kTechIdSafetyLamp,
        funding: ResearchFundingLevel.medium,
        turns: 11,
        treasury: 5000,
        techUnlocked: prereqs,
      ).players.single;
      expect(after11.techUnlocked?[kTechIdSafetyLamp], isNot(true));
      expect(
        (after11.researchProgressByTechId ?? const {})[kTechIdSafetyLamp],
        3300,
      );

      final after12 = runResearchTurns(
        techId: kTechIdSafetyLamp,
        funding: ResearchFundingLevel.medium,
        turns: 12,
        treasury: 5000,
        techUnlocked: prereqs,
      ).players.single;
      expect(after12.techUnlocked?[kTechIdSafetyLamp], isTrue);
    });

    test('Low funding adds exactly 100 RP per turn to a tier-2 tech', () {
      // wind_saw_mill is tier-2 (cost 2400); prereq saw_mill unlocked.
      final after = runResearchTurns(
        techId: kTechIdWindSawMill,
        funding: ResearchFundingLevel.low,
        turns: 1,
        treasury: 200,
        techUnlocked: const {kTechIdSawMill: true},
      ).players.single;
      expect(
        (after.researchProgressByTechId ?? const {})[kTechIdWindSawMill],
        100,
      );
      expect(after.techUnlocked?[kTechIdWindSawMill], isNot(true));
    });

    test(
      'Industrial Funding of Research adds floor(300*1.2)=360 RP to a military '
      'tier-2 tech at Medium',
      () {
        // improved_iron_weapons is a tier-2 military tech; pre-unlock its
        // prerequisites plus Industrial Funding of Research for the +20% bonus.
        const unlocked = {
          kTechIdOrganisedRegiments: true,
          kTechIdIronMining: true,
          kTechIdIndustrialFundingOfResearch: true,
        };
        final after = runResearchTurns(
          techId: kTechIdImprovedIronWeapons,
          funding: ResearchFundingLevel.medium,
          turns: 1,
          treasury: 500,
          techUnlocked: unlocked,
        ).players.single;
        expect(
          (after.researchProgressByTechId ??
              const {})[kTechIdImprovedIronWeapons],
          360,
        );
      },
    );
  });
}
