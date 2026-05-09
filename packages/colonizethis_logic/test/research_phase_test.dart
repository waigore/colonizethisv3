import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_test_support.dart';

void main() {
  group('Research phase', () {
    test(
      'resolveResearchPhase returns game unchanged when no research orders',
      () {
        final game = researchPhaseTestBaseGame(treasury: 1000);
        final result = resolveResearchPhase(game, const Orders());
        expect(identical(result, game), isTrue);
      },
    );

    test('resolveResearchPhase adds envy evidence when AI mirrors human '
        'research category same turn', () {
      final game = researchPhaseTestHumanAiMirrorResearchGame();
      final orders = Orders(
        researchOrdersByPlayerId: {
          'h1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
          'a1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.maximum,
            ),
          ],
        },
      );
      final next = resolveResearchPhase(game, orders);
      final envy = next.dossierEvidenceEntries
          .where((e) => e.agendaType == 'envy')
          .toList();
      expect(envy, isNotEmpty);
      expect(envy.every((e) => e.subjectId == 'a1'), isTrue);
      expect(next.lastHumanCompletedResearchCategory, 'gathering');
      expect(next.lastHumanResearchCategoryCompletionTurn, 2);
    });

    test('resolveResearchPhase skips player when researchSlots is zero', () {
      final game = researchPhaseTestBaseGame(treasury: 2000, researchSlots: 0);
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
      final result = resolveResearchPhase(game, orders);
      expect(result.players.single.treasury, 2000);
      expect(
        result.players.single.researchProgressByTechId ?? const {},
        isEmpty,
      );
    });

    test(
      'resolveResearchPhase clears progress when slot canceled (empty techId)',
      () {
        const initialTreasury = 500;
        final game = researchPhaseTestBaseGame(
          treasury: initialTreasury,
          techUnlocked: const {},
          progress: const {kTechIdCropRotation: 10},
          researchSlots: 1,
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: '',
                funding: ResearchFundingLevel.none,
              ),
            ],
          },
        );
        final result = resolveResearchPhase(game, orders);
        final player = result.players.single;
        expect(player.treasury, initialTreasury);
        expect(player.researchProgressByTechId ?? const {}, isEmpty);
      },
    );

    test(
      'resolveResearchPhase keeps progress for tech still assigned in another slot',
      () {
        const initialTreasury = 500;
        final game = researchPhaseTestBaseGame(
          treasury: initialTreasury,
          techUnlocked: const {kTechIdSawMill: true},
          progress: const {kTechIdWindSawMill: 80},
          researchSlots: 2,
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: '',
                funding: ResearchFundingLevel.none,
              ),
              ResearchOrder(
                slotIndex: 1,
                techId: kTechIdWindSawMill,
                funding: ResearchFundingLevel.none,
              ),
            ],
          },
        );
        final result = resolveResearchPhase(game, orders);
        final player = result.players.single;
        expect(player.treasury, initialTreasury);
        expect(player.researchProgressByTechId, {kTechIdWindSawMill: 80});
      },
    );

    test(
      'resolveResearchPhase skips player when that player has no research orders',
      () {
        final game = researchPhaseTestTwoHumanPlayersOrdersTurn0();
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
        final result = resolveResearchPhase(game, orders);
        expect(result.players.length, 2);
        final rp2 = result.players.where((p) => p.id == 'p2').single;
        expect(rp2.treasury, 500);
        expect(rp2.researchProgressByTechId ?? const {}, isEmpty);
      },
    );

    test('accumulates research progress and unlocks tech when cost reached', () {
      final tech = techById(kTechIdCropRotation)!;
      // Maximum funding costs 1000 gold/turn (per SPEC/game/tech-tree.md)
      final game = researchPhaseTestBaseGame(treasury: 2000, techUnlocked: const {});

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
        final game = researchPhaseTestBaseGame(treasury: 100, techUnlocked: const {});
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
      final game = researchPhaseTestBaseGame(treasury: 2000, techUnlocked: const {});
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

    test('all funding levels match spec values via game behavior', () {
      // Use wind_saw_mill (cost 160) with prereq met so low funding does not complete in one turn.
      const prereqMet = {kTechIdSawMill: true};

      // Low: 50 gold, 100 RP (no unlock; 100 < 160)
      var game = researchPhaseTestBaseGame(treasury: 100, techUnlocked: prereqMet);
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

    test('completing University sets researchSlots to 4', () {
      // SPEC/game/tech-tree.md: 3 slots by default, 4 with University tech.
      // University requires: money_lending, apprentice_workers, printing_press
      final game = researchPhaseTestBaseGame(
        treasury: 3000,
        techUnlocked: const {
          kTechIdMoneyLending: true,
          kTechIdApprenticeWorkers: true,
          kTechIdPrintingPress: true,
        },
      );
      final orders = Orders(
        researchOrdersByPlayerId: {
          'p1': const [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdUniversity,
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
      expect(player.techUnlocked![kTechIdUniversity], isTrue);
      expect(player.researchSlots, 4);
    });

    test('Money Lending allows limited negative treasury for research', () {
      // Money Lending: allow research spending to drive treasury down to -500.
      final tech = techById(kTechIdCropRotation)!;
      expect(
        tech.cost,
        lessThan(2500),
      ); // sanity: one turn of max funding can complete

      final game = researchPhaseTestBaseGame(
        treasury: 500,
        techUnlocked: const {kTechIdLandEnclosure: true, kTechIdMoneyLending: true},
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
      final player = next.players.single;

      // With Money Lending, treasury may go as low as -500; maximum funding
      // (1000 cost) from 500 should be allowed and either complete the tech or
      // at least deduct the cost and add progress.
      expect(player.treasury, lessThanOrEqualTo(500));
      expect(player.treasury, greaterThanOrEqualTo(-500));
      final unlocked = player.techUnlocked ?? const {};
      final progress = player.researchProgressByTechId ?? const {};
      expect(
        unlocked[kTechIdCropRotation] == true || progress[kTechIdCropRotation] != null,
        isTrue,
      );
    });

    test('Banking extends research debt floor to -1000 with Money Lending', () {
      final game = researchPhaseTestBaseGame(
        treasury: 0,
        techUnlocked: const {
          kTechIdLandEnclosure: true,
          kTechIdMoneyLending: true,
          kTechIdTradeFairs: true,
          kTechIdBanking: true,
        },
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
      final player = next.players.single;
      expect(player.treasury, greaterThanOrEqualTo(-1000));
      expect(player.treasury, -1000);
    });

    test(
      'duplicate slotIndex: only one order per slot applied (last wins), no double spend',
      () {
        // SPEC: one assignment per slot. If list has two orders for same slot, resolver uses one (last wins).
        final game = researchPhaseTestBaseGame(treasury: 2000, techUnlocked: const {});
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: kTechIdCropRotation,
                funding: ResearchFundingLevel.low,
              ),
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
        final player = next.players.single;
        // Last wins => maximum only: 1000 spent, 2500 RP => crop_rotation (cost 120) unlocks.
        expect(player.treasury, 1000);
        expect(player.techUnlocked![kTechIdCropRotation], isTrue);
        // If both were applied we would have 1050 spent and dual progress; so no double spend.
      },
    );
  });
}
