import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_test_support.dart';

void main() {
  group('Research phase tech effects', () {
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
