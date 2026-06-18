import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_test_support.dart';

void main() {
  group('Research phase funding', () {
    test('accumulates research progress and unlocks tech when cost reached', () {
      final tech = techById(kTechIdCropRotation)!;
      // Maximum funding costs 1000 gold/turn (per SPEC/game/tech-tree.md)
      final game = researchPhaseTestBaseGame(
        treasury: 2000,
        techUnlocked: const {},
      );

      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );

      final topology = const MapTopology();
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(game: game, topology: topology, orders: orders),
      );
      final player = next.players.single;

      // One turn of maximum funding should make progress > 0 and reduce treasury.
      expect(player.treasury, lessThan(game.players.single.treasury));
      final progress = player.researchProgressByTechId ?? const {};
      final unlocked = player.techUnlocked ?? const {};

      if (progress.isNotEmpty) {
        // Research not yet complete; progress should be less than cost and tech not unlocked.
        expect(progress[kTechIdCropRotation], isNotNull);
        expect(progress[kTechIdCropRotation], lessThan(tech.cost));
        expect(unlocked[kTechIdCropRotation], isNot(true));
      } else {
        // If cost is small, research may complete in a single turn.
        expect(unlocked[kTechIdCropRotation], isTrue);
      }
    });

    test('applies prerequisite rule: cannot research tech without prereqs', () {
      // No spend when prereq not met; use enough treasury in case logic ever applied
      final game = researchPhaseTestBaseGame(
        treasury: 2000,
        techUnlocked: const {}, // saw_mill not researched
      );

      final orders = Orders(
        researchOrdersByPlayerId: const {
          'p1': [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdWindSawMill,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );

      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      final player = next.players.single;

      // Treasury unchanged and no progress recorded because prerequisite not met.
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
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: kTechIdCropRotation,
                funding: ResearchFundingLevel.none,
              ),
            ],
          },
        );
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: const MapTopology(),
            orders: orders,
          ),
        );
        expect(next.players.single.treasury, 100);
        expect(
          next.players.single.researchProgressByTechId ?? const {},
          isEmpty,
        );
      },
    );

    test('research with low funding deducts treasury and adds progress', () {
      // Use wind_saw_mill (tier-2 cost 2400) with prereq so 100 RP does not
      // complete in one turn. SPEC/game/tech-tree.md § Research Model.
      final game = researchPhaseTestBaseGame(
        treasury: 100,
        techUnlocked: const {kTechIdSawMill: true},
      );
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdWindSawMill,
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      // Low funding: 50 gold cost, 100 RP per turn (per SPEC/game/tech-tree.md)
      expect(next.players.single.treasury, 50);
      expect(
        (next.players.single.researchProgressByTechId ??
            const {})[kTechIdWindSawMill],
        100,
      );
    });

    test('research with maximum funding has efficiency bonus', () {
      final game = researchPhaseTestBaseGame(
        treasury: 2000,
        techUnlocked: const {},
      );
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      // Maximum funding: 1000 gold cost, 2500 RP per turn (2.5x efficiency).
      // crop_rotation tier-1 cost is 1800, so 2500 RP >= 1800 unlocks the tech
      // and progress is cleared. SPEC/game/tech-tree.md § Research Model.
      expect(next.players.single.treasury, 1000);
      expect(next.players.single.techUnlocked![kTechIdCropRotation], isTrue);
    });

    test(
      'debt cap rejects allocation that would breach max debt (no money lending)',
      () {
        // maxDebt = 0 without Money Lending: treasury 30, low funding cost 50
        // would reach -20, below the floor, so the order is rejected with no
        // treasury spend and no progress. Refs #3416 (research context).
        final game = researchPhaseTestBaseGame(
          treasury: 30,
          techUnlocked: const {kTechIdSawMill: true},
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: kTechIdWindSawMill,
                funding: ResearchFundingLevel.low,
              ),
            ],
          },
        );
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: const MapTopology(),
            orders: orders,
          ),
        );
        expect(next.players.single.treasury, 30);
        expect(
          next.players.single.researchProgressByTechId ?? const {},
          isEmpty,
        );
        expect(
          next.players.single.techUnlocked?[kTechIdWindSawMill],
          isNot(true),
        );
      },
    );

    test(
      'debt cap allows treasury to go negative within money-lending floor',
      () {
        // maxDebt = 500 with Money Lending: treasury 30, low funding cost 50
        // reaches -20 which is within the floor, so the order applies.
        final game = researchPhaseTestBaseGame(
          treasury: 30,
          techUnlocked: const {kTechIdSawMill: true, kTechIdMoneyLending: true},
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: kTechIdWindSawMill,
                funding: ResearchFundingLevel.low,
              ),
            ],
          },
        );
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: const MapTopology(),
            orders: orders,
          ),
        );
        expect(next.players.single.treasury, -20);
        expect(
          (next.players.single.researchProgressByTechId ??
              const {})[kTechIdWindSawMill],
          100,
        );
      },
    );

    test('all funding levels match spec values via game behavior', () {
      // Use wind_saw_mill (tier-2 cost 2400) with prereq met. Only Maximum
      // funding (2500 RP) completes it in one turn; Low/Medium/High accrue
      // partial progress. SPEC/game/tech-tree.md § Research Model.
      const prereqMet = {kTechIdSawMill: true};

      // Low: 50 gold, 100 RP (no unlock; 100 < 2400)
      var game = researchPhaseTestBaseGame(
        treasury: 100,
        techUnlocked: prereqMet,
      );
      var orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdWindSawMill,
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
      );
      var next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      expect(next.players.single.treasury, 50);
      expect(
        (next.players.single.researchProgressByTechId ??
            const {})[kTechIdWindSawMill],
        100,
      );

      // Medium: 150 gold, 300 RP (no unlock; 300 < 2400)
      game = researchPhaseTestBaseGame(treasury: 200, techUnlocked: prereqMet);
      orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdWindSawMill,
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );
      next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      expect(next.players.single.treasury, 50);
      expect(
        (next.players.single.researchProgressByTechId ??
            const {})[kTechIdWindSawMill],
        300,
      );
      expect(
        next.players.single.techUnlocked?[kTechIdWindSawMill],
        isNot(true),
      );

      // High: 400 gold, 800 RP (no unlock; 800 < 2400)
      game = researchPhaseTestBaseGame(treasury: 500, techUnlocked: prereqMet);
      orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdWindSawMill,
              funding: ResearchFundingLevel.high,
            ),
          ],
        },
      );
      next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      expect(next.players.single.treasury, 100);
      expect(
        (next.players.single.researchProgressByTechId ??
            const {})[kTechIdWindSawMill],
        800,
      );
      expect(
        next.players.single.techUnlocked?[kTechIdWindSawMill],
        isNot(true),
      );

      // Maximum: 1000 gold, 2500 RP (2.5x efficiency, unlocks)
      game = researchPhaseTestBaseGame(treasury: 1500, techUnlocked: prereqMet);
      orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdWindSawMill,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );
      next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      expect(next.players.single.treasury, 500);
      expect(next.players.single.techUnlocked![kTechIdWindSawMill], isTrue);
    });
  });

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
              ResearchOrder(
                slotIndex: 0,
                techId: techId,
                funding: funding,
              ),
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
      const prereqs = {
        kTechIdLargeCoalMines: true,
        kTechIdDynamite: true,
      };
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
