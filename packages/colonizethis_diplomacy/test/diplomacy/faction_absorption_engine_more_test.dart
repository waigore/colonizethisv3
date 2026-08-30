import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('FactionAbsorptionEngine more', () {
    test(
      'great power absorption leaves colony/boycott state untouched when removed GP holds none',
      () {
        final game = diplomacyGame(
          id: 'gid',
          players: const [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: true,
              treasury: 100000,
            ),
            Player(
              id: 'gp2',
              displayName: 'B',
              isHuman: false,
              treasury: 0,
            ),
          ],
          tribes: const [Tribe(id: 'tB', displayName: 'Colony of gp1')],
          colonyStates: const [
            ColonyState(tribeId: 'tB', colonyOfGpId: 'gp1', sinceTurn: 3),
          ],
          boycottStates: const [
            BoycottState(gpId: 'gp1', targetGpId: 'gp3', sinceTurn: 6),
          ],
        );

        final next = FactionAbsorptionEngine.absorbGreatPowerIntoGp(
          game,
          'gp1',
          'gp2',
        );

        expect(next.colonyStates, hasLength(1));
        expect(next.colonyStates.single.colonyOfGpId, 'gp1');
        expect(next.boycottStates, hasLength(1));
        expect(next.boycottStates.single.targetGpId, 'gp3');
      },
    );
  });
}
