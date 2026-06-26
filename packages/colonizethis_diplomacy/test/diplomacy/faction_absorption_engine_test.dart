import 'package:colonizethis_diplomacy/src/diplomacy/faction_absorption_engine.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('FactionAbsorptionEngine', () {
    test(
      'absorbGreatPowerIntoGp is a no-op when absorber or target is missing',
      () {
        final game = TestFixtures.minimalGame(
          players: const [
            Player(id: 'only', displayName: 'Solo', isHuman: true),
          ],
        );
        expect(
          identical(
            game,
            FactionAbsorptionEngine.absorbGreatPowerIntoGp(game, 'gpA', 'gpB'),
          ),
          isTrue,
        );
      },
    );

    test(
      'minor absorption does not remap GP-only persisted maps (intentional)',
      () {
        // Tile in a province **not** transferred by bulk ownership apply, so
        // `purchasedTilesByTileKey` is not cleared by province transfer logic.
        const tileKey = 'oldWorld|p2|0|0';
        final game =
            TestFixtures.minimalGame(
              players: const [
                Player(
                  id: 'gp1',
                  displayName: 'GP',
                  isHuman: true,
                  treasury: 50000,
                ),
              ],
              minorNations: [MinorNation(id: 'mn1', displayName: 'Minor')],
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    ownerId: 'mn1',
                    fortLevel: 0,
                  ),
                  Province(
                    id: 'oldWorld|p2',
                    regionId: 'oldWorld',
                    ownerId: 'gp1',
                    fortLevel: 0,
                  ),
                ],
              ),
              purchasedTilesByTileKey: {tileKey: 'mn1'},
              playerProspectedTiles: {
                'mn1': {'oldWorld|p1|1|1'},
              },
            ).copyWith(
              generals: const [General(id: 'gen1', ownerId: 'mn1')],
              aiControlByGpId: {'mn1': true},
            );

        final next = FactionAbsorptionEngine.absorbMinorOrTribeIntoGp(
          game,
          'gp1',
          'mn1',
          1,
        );

        expect(next.minorNations, isEmpty);
        expect(
          next.worldState.oldWorld.provinces
              .singleWhere((p) => p.id == 'oldWorld|p1')
              .ownerId,
          'gp1',
        );
        expect(
          next.worldState.purchasedTilesByTileKey[tileKey],
          'mn1',
          reason: 'minor path skips purchasedTilesByTileKey remapping',
        );
        expect(next.generals.single.ownerId, 'mn1');
        expect(next.aiControlByGpId['mn1'], isTrue);
        expect(next.worldState.playerProspectedTiles['mn1'], {
          'oldWorld|p1|1|1',
        });
      },
    );

    test(
      'great power absorption remaps GP-only persisted state to absorber',
      () {
        // Purchased entry sits on gp1-owned province so bulk transfer of gp2
        // provinces does not strip this key; GP absorption remaps owner id.
        const tileKey = 'oldWorld|p2|0|0';
        final ws =
            TestFixtures.worldStateAtOrdersPhase(
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    ownerId: 'gp2',
                    fortLevel: 0,
                  ),
                  Province(
                    id: 'oldWorld|p2',
                    regionId: 'oldWorld',
                    ownerId: 'gp1',
                    fortLevel: 0,
                  ),
                ],
              ),
            ).copyWith(
              purchasedTilesByTileKey: {tileKey: 'gp2'},
              playerProspectedTiles: {
                'gp2': {'t1'},
              },
            );

        final game =
            TestFixtures.twoPlayerGame(
              player1: const Player(
                id: 'gp1',
                displayName: 'A',
                isHuman: true,
                treasury: 100000,
              ),
              player2: const Player(
                id: 'gp2',
                displayName: 'B',
                isHuman: false,
                treasury: 0,
              ),
              worldState: ws,
            ).copyWith(
              generals: const [General(id: 'g1', ownerId: 'gp2')],
              aiControlByGpId: {'gp2': true, 'gp1': false},
              aiSeedByGpId: {'gp2': 42},
              hiddenAgendaByGpId: {'gp2': 'hidden'},
              politicalGlyphByPlayerId: {'gp2': 'x'},
            );

        final next = FactionAbsorptionEngine.absorbGreatPowerIntoGp(
          game,
          'gp1',
          'gp2',
        );

        expect(next.players.map((p) => p.id), ['gp1']);
        expect(next.generals.single.ownerId, 'gp1');
        expect(next.worldState.purchasedTilesByTileKey[tileKey], 'gp1');
        expect(
          next.worldState.playerProspectedTiles.containsKey('gp2'),
          isFalse,
        );
        expect(next.worldState.playerProspectedTiles['gp1'], contains('t1'));
        expect(next.aiControlByGpId.containsKey('gp2'), isFalse);
        expect(next.aiSeedByGpId.containsKey('gp2'), isFalse);
        expect(next.hiddenAgendaByGpId.containsKey('gp2'), isFalse);
        expect(next.politicalGlyphByPlayerId.containsKey('gp2'), isFalse);
      },
    );
  });
}
