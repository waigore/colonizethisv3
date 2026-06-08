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
  });
}
