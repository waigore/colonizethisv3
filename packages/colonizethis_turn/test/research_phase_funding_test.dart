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
      // Use wind_saw_mill (cost 160) with prereq so 100 RP does not complete in one turn.
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
      // crop_rotation cost is 120, so tech unlocks and progress is cleared.
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
      // Use wind_saw_mill (cost 160) with prereq met so low funding does not complete in one turn.
      const prereqMet = {kTechIdSawMill: true};

      // Low: 50 gold, 100 RP (no unlock; 100 < 160)
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

      // Medium: 150 gold, 300 RP (unlocks wind_saw_mill)
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
      expect(next.players.single.techUnlocked![kTechIdWindSawMill], isTrue);

      // High: 400 gold, 800 RP (unlocks)
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
      expect(next.players.single.techUnlocked![kTechIdWindSawMill], isTrue);

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
}
