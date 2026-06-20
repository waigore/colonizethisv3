import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds a single-human-player [Game] for slot-occupancy persistence tests.
///
/// SPEC/program/research-resolution.md § Slot occupancy persistence.
Game _slotAssignmentGame({
  required int treasury,
  required int researchSlots,
  Map<String, bool>? techUnlocked,
  Map<String, int>? progress,
  Map<int, ResearchSlotAssignment>? slotAssignments,
}) {
  final player = Player(
    id: 'p1',
    displayName: 'Player 1',
    isHuman: true,
    treasury: treasury,
    techUnlocked: techUnlocked,
    researchProgressByTechId: progress,
    researchSlots: researchSlots,
    researchSlotAssignments: slotAssignments,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  );
  return Game(id: 'g', worldState: world, players: [player]);
}

void main() {
  group('Research phase slot-occupancy persistence', () {
    test(
      'persists slot assignment back to Player after an incomplete turn',
      () {
        final game = _slotAssignmentGame(
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
        final game = _slotAssignmentGame(
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
        final game = _slotAssignmentGame(
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

    test(
      'completing a tech unlocks it, frees the slot, and prunes progress',
      () {
        final game = _slotAssignmentGame(
          treasury: 2000,
          researchSlots: 1,
          techUnlocked: const {},
          slotAssignments: const {
            0: ResearchSlotAssignment(
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.maximum,
            ),
          },
        );

        final result = resolveResearchPhase(game, const Orders());
        final player = result.players.single;

        // Maximum funding: 2500 RP >= 1800 cost -> unlock.
        expect(player.techUnlocked?[kTechIdCropRotation], isTrue);
        expect(
          (player.researchProgressByTechId ?? const {})[kTechIdCropRotation],
          isNull,
        );
        expect(player.researchSlotAssignments ?? const {}, isEmpty);
      },
    );

    test(
      'cancelling an occupied slot frees it and forfeits accrued progress',
      () {
        final game = _slotAssignmentGame(
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

        expect(player.treasury, 2000);
        expect(player.researchProgressByTechId ?? const {}, isEmpty);
        expect(player.researchSlotAssignments ?? const {}, isEmpty);
      },
    );

    test(
      'drops persisted assignments with unknown tech or out-of-bounds slot',
      () {
        final game = _slotAssignmentGame(
          treasury: 2000,
          researchSlots: 2,
          techUnlocked: const {},
          slotAssignments: const {
            0: ResearchSlotAssignment(
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.medium,
            ),
            1: ResearchSlotAssignment(
              techId: 'nonexistent_tech_id',
              funding: ResearchFundingLevel.medium,
            ),
            5: ResearchSlotAssignment(
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.medium,
            ),
          },
        );

        final result = resolveResearchPhase(game, const Orders());
        final player = result.players.single;

        // Only the valid slot-0 assignment survives; the unknown-tech (slot 1)
        // and out-of-bounds (slot 5) entries are dropped.
        expect(player.researchSlotAssignments, {
          0: const ResearchSlotAssignment(
            techId: kTechIdCropRotation,
            funding: ResearchFundingLevel.medium,
          ),
        });
        expect(player.researchProgressByTechId?[kTechIdCropRotation], 300);
        expect(player.treasury, 1850);
      },
    );
  });
}
