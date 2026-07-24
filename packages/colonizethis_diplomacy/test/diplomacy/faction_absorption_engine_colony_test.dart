import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

void main() {
  group('FactionAbsorptionEngine colony marking', () {
    test(
      'markTribeAsColony deducts cost, records ColonyState, keeps tribe + provinces',
      () {
        const ow = 'oldWorld';
        final game = diplomacyGame(
          players: const [
            Player(
              id: 'gp1',
              displayName: 'GP',
              isHuman: true,
              treasury: 50000,
            ),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: '$ow|p1',
                regionId: ow,
                ownerId: 'tribe1',
                fortLevel: 0,
              ),
            ],
          ),
        );

        final next = FactionAbsorptionEngine.markTribeAsColony(
          game,
          'gp1',
          'tribe1',
          7,
        );

        expect(next.tribes.any((t) => t.id == 'tribe1'), isTrue);
        expect(
          next.worldState.oldWorld.provinces
              .singleWhere((p) => p.id == '$ow|p1')
              .ownerId,
          'tribe1',
          reason: 'colony tribe keeps its provinces',
        );
        expect(next.colonyStates, hasLength(1));
        expect(next.colonyStates.single.colonyOfGpId, 'gp1');
        expect(next.colonyStates.single.sinceTurn, 7);
        expect(next.playerById('gp1')!.treasury, 50000 - 7000);
      },
    );

    test('markTribeAsColony replaces an existing ColonyState for the tribe', () {
      final game = diplomacyGame(
        players: const [
          Player(
            id: 'gp2',
            displayName: 'GP2',
            isHuman: false,
            treasury: 50000,
          ),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
        colonyStates: const [
          ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
        ],
      );

      final next = FactionAbsorptionEngine.markTribeAsColony(
        game,
        'gp2',
        'tribe1',
        9,
      );

      expect(next.colonyStates.where((c) => c.tribeId == 'tribe1'), hasLength(1));
      expect(next.colonyStates.single.colonyOfGpId, 'gp2');
      expect(next.colonyStates.single.sinceTurn, 9);
    });
  });
}
