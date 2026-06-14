import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_phase_test_support.dart';

int _generalCountFor(Game game, String playerId) =>
    game.generals.where((g) => g.ownerId == playerId).length;

void main() {
  group('Research phase general cap (SPEC/game/military-generals.md)', () {
    test(
      'completing organised_regiments raises cap to 2 and spawns a general',
      () {
        final game = researchPhaseTestBaseGame(
          treasury: 5000,
          techUnlocked: const {kTechIdLandEnclosure: true},
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            'p1': const [
              ResearchOrder(
                slotIndex: 0,
                techId: kTechIdOrganisedRegiments,
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
        expect(player.techUnlocked![kTechIdOrganisedRegiments], isTrue);
        expect(player.generalCap, 2);
        expect(_generalCountFor(next, 'p1'), 2);
        expect(
          next.generals.where((g) => g.ownerId == 'p1' && g.medals == 0).length,
          2,
        );
      },
    );

    test('researching a non-military tech leaves cap at 1', () {
      final game = researchPhaseTestBaseGame(
        treasury: 5000,
        techUnlocked: const {kTechIdLandEnclosure: true},
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
      expect(player.generalCap, 1);
      expect(_generalCountFor(next, 'p1'), 1);
    });
  });
}
