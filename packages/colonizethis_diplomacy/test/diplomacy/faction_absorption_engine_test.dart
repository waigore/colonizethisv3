import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

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

    test(
      'great power absorption clears colonies and boycotts of the removed GP',
      () {
        // gp1 absorbs gp2 (gp2 is removed). gp2 is the suzerain of colony
        // tribe `tA` and issuer/target of boycotts; a colony of gp1 and a
        // boycott between unrelated GPs must survive. Refs #3753 R5.5 / R6.4.
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
            ).copyWith(
              tribes: const [
                Tribe(id: 'tA', displayName: 'Colony of gp2'),
                Tribe(id: 'tB', displayName: 'Colony of gp1'),
              ],
              colonyStates: const [
                ColonyState(tribeId: 'tA', colonyOfGpId: 'gp2', sinceTurn: 2),
                ColonyState(tribeId: 'tB', colonyOfGpId: 'gp1', sinceTurn: 3),
              ],
              boycottStates: const [
                // Issued by the removed GP.
                BoycottState(gpId: 'gp2', targetGpId: 'gp1', sinceTurn: 4),
                // Directed at the removed GP.
                BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 5),
                // Unrelated to gp2; must survive.
                BoycottState(gpId: 'gp1', targetGpId: 'gp3', sinceTurn: 6),
              ],
            );

        final next = FactionAbsorptionEngine.absorbGreatPowerIntoGp(
          game,
          'gp1',
          'gp2',
        );

        expect(next.players.map((p) => p.id), ['gp1']);
        // Colony of the removed GP is dropped; colony of the absorber survives.
        expect(next.colonyStates.map((c) => c.tribeId), ['tB']);
        expect(next.colonyStates.single.colonyOfGpId, 'gp1');
        expect(next.tribes.map((t) => t.id), containsAll(['tA', 'tB']));
        // Boycotts touching the removed GP (either side) are cleared; the
        // unrelated boycott survives.
        expect(next.boycottStates, hasLength(1));
        expect(next.boycottStates.single.gpId, 'gp1');
        expect(next.boycottStates.single.targetGpId, 'gp3');
      },
    );

    test(
      'great power absorption leaves colony/boycott state untouched when removed GP holds none',
      () {
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
            ).copyWith(
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

    test(
      'markTribeAsColony deducts cost, records ColonyState, keeps tribe + provinces',
      () {
        const ow = 'oldWorld';
        final game = TestFixtures.minimalGame(
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
        // Cost = base 5000 + 1 province * 2000 = 7000.
        expect(next.playerById('gp1')!.treasury, 50000 - 7000);
      },
    );

    test('markTribeAsColony replaces an existing ColonyState for the tribe', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(
            id: 'gp2',
            displayName: 'GP2',
            isHuman: false,
            treasury: 50000,
          ),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
      ).copyWith(
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
