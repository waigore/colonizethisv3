import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_slot_assignment_cases.dart';

void main() {
  group('Research phase slot-occupancy persistence', () {
    test(
      'persists slot assignment back to Player after an incomplete turn',
      () {
        final game = slotAssignmentGame(
          treasury: 2000,
          researchSlots: 1,
          techUnlocked: const {},
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: kTechIdCropRotation,
                funding: ResearchFundingLevel.medium,
              ),
            ],
          },
        );

        final result = resolveResearchPhase(game, orders);
        final player = result.players.single;

        // Medium funding: 150 gold, 300 RP; crop_rotation (tier-1) costs 1800
        // so the tech is not yet unlocked.
        expect(player.treasury, 1850);
        expect(player.researchProgressByTechId?[kTechIdCropRotation], 300);
        expect(player.techUnlocked?[kTechIdCropRotation], isNot(true));
        expect(player.researchSlotAssignments, {
          0: const ResearchSlotAssignment(
            techId: kTechIdCropRotation,
            funding: ResearchFundingLevel.medium,
          ),
        });
      },
    );

    test(
      'persisted assignment keeps researching with no fresh order this turn',
      () {
        final game = slotAssignmentGame(
          treasury: 2000,
          researchSlots: 1,
          techUnlocked: const {},
          progress: const {kTechIdCropRotation: 300},
          slotAssignments: const {
            0: ResearchSlotAssignment(
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.medium,
            ),
          },
        );

        // No order submitted for the player this turn.
        final result = resolveResearchPhase(game, const Orders());
        final player = result.players.single;

        // The slot keeps researching at its persisted Medium funding:
        // progress accrues by another 300 RP and the slot stays occupied.
        expect(player.treasury, 1850);
        expect(player.researchProgressByTechId?[kTechIdCropRotation], 600);
        expect(player.researchSlotAssignments, {
          0: const ResearchSlotAssignment(
            techId: kTechIdCropRotation,
            funding: ResearchFundingLevel.medium,
          ),
        });
      },
    );

    test(
      'retains progress while the tech still occupies a slot',
      () {
        final game = slotAssignmentGame(
          treasury: 2000,
          researchSlots: 1,
          techUnlocked: const {},
          progress: const {kTechIdCropRotation: 300},
          slotAssignments: const {
            0: ResearchSlotAssignment(
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.none,
            ),
          },
        );

        final result = resolveResearchPhase(game, const Orders());
        final player = result.players.single;

        // None funding: no spend, no extra progress, but progress is retained
        // because the tech still occupies its slot.
        expect(player.treasury, 2000);
        expect(player.researchProgressByTechId?[kTechIdCropRotation], 300);
        expect(player.researchSlotAssignments, isNotEmpty);
      },
    );

    registerResearchPhaseSlotCompletionCases();
  });
}
