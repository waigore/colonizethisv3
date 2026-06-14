import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWith({
  required List<Player> players,
  List<General> generals = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    generals: generals,
  );
}

Player _gp(String id, {Map<String, bool>? tech, int? cap}) => Player(
  id: id,
  displayName: id,
  isHuman: false,
  techUnlocked: tech,
  generalCap: cap,
);

List<General> _generalsFor(Game game, String ownerId) =>
    game.generals.where((g) => g.ownerId == ownerId).toList();

void main() {
  group('generalCapForUnlockedTechs (SPEC/game/military-generals.md)', () {
    test('null or empty techs → cap 1', () {
      expect(generalCapForUnlockedTechs(null), 1);
      expect(generalCapForUnlockedTechs(const {}), 1);
    });

    test('organised_regiments → cap 2', () {
      expect(generalCapForUnlockedTechs({kTechIdOrganisedRegiments: true}), 2);
    });

    test('national_bureaucracy → cap 3', () {
      expect(generalCapForUnlockedTechs({kTechIdNationalBureaucracy: true}), 3);
    });

    test('improved_infantry_tactics → cap 3', () {
      expect(
        generalCapForUnlockedTechs({kTechIdImprovedInfantryTactics: true}),
        3,
      );
    });

    test(
      'national_bureaucracy + improved_infantry_tactics do not stack → 3',
      () {
        expect(
          generalCapForUnlockedTechs({
            kTechIdNationalBureaucracy: true,
            kTechIdImprovedInfantryTactics: true,
          }),
          3,
        );
      },
    );

    test('nationalism → cap 4', () {
      expect(generalCapForUnlockedTechs({kTechIdNationalism: true}), 4);
    });

    test('false-valued tech entries are ignored', () {
      expect(generalCapForUnlockedTechs({kTechIdOrganisedRegiments: false}), 1);
    });
  });

  group('syncGeneralCapsFromTech', () {
    test('GP at start has cap 1 and exactly one general with 0 medals', () {
      final game = syncGeneralCapsFromTech(_gameWith(players: [_gp('gp1')]));
      expect(game.players.single.generalCap, 1);
      final generals = _generalsFor(game, 'gp1');
      expect(generals.length, 1);
      expect(generals.single.medals, 0);
    });

    test(
      'organised_regiments raises cap to 2 and spawns a 0-medal general',
      () {
        var game = syncGeneralCapsFromTech(_gameWith(players: [_gp('gp1')]));
        // Researcher gains a medal on the existing general before tech unlock.
        game = game.copyWith(
          generals: [game.generals.single.copyWith(medals: 3)],
          players: [
            game.players.single.copyWith(
              techUnlocked: {kTechIdOrganisedRegiments: true},
            ),
          ],
        );
        game = syncGeneralCapsFromTech(game);
        expect(game.players.single.generalCap, 2);
        final generals = _generalsFor(game, 'gp1');
        expect(generals.length, 2);
        // Existing general (with medals) preserved; the new one starts at 0.
        expect(generals.where((g) => g.medals == 3).length, 1);
        expect(generals.where((g) => g.medals == 0).length, 1);
      },
    );

    test('national_bureaucracy gives cap 3 with three generals', () {
      final game = syncGeneralCapsFromTech(
        _gameWith(
          players: [
            _gp('gp1', tech: {kTechIdNationalBureaucracy: true}),
          ],
        ),
      );
      expect(game.players.single.generalCap, 3);
      expect(_generalsFor(game, 'gp1').length, 3);
    });

    test('nationalism gives cap 4 with four generals', () {
      final game = syncGeneralCapsFromTech(
        _gameWith(
          players: [
            _gp('gp1', tech: {kTechIdNationalism: true}),
          ],
        ),
      );
      expect(game.players.single.generalCap, 4);
      expect(_generalsFor(game, 'gp1').length, 4);
    });

    test('researching both nb and iit keeps cap at 3 (no stack)', () {
      final game = syncGeneralCapsFromTech(
        _gameWith(
          players: [
            _gp(
              'gp1',
              tech: {
                kTechIdNationalBureaucracy: true,
                kTechIdImprovedInfantryTactics: true,
              },
            ),
          ],
        ),
      );
      expect(game.players.single.generalCap, 3);
      expect(_generalsFor(game, 'gp1').length, 3);
    });

    test('multiple GPs each get independent caps and unique general ids', () {
      final game = syncGeneralCapsFromTech(
        _gameWith(
          players: [
            _gp('gp1'),
            _gp('gp2', tech: {kTechIdOrganisedRegiments: true}),
          ],
        ),
      );
      expect(game.players[0].generalCap, 1);
      expect(game.players[1].generalCap, 2);
      expect(_generalsFor(game, 'gp1').length, 1);
      expect(_generalsFor(game, 'gp2').length, 2);
      final ids = game.generals.map((g) => g.id).toSet();
      expect(ids.length, game.generals.length);
    });
  });

  group('reconcileGeneralsToGeneralCap (load-time, spawn-only)', () {
    test('persisted cap with short roster spawns missing generals', () {
      final game = reconcileGeneralsToGeneralCap(
        _gameWith(
          players: [_gp('gp1', cap: 3)],
          generals: const [General(id: 'gp1_gen_0', ownerId: 'gp1', medals: 2)],
        ),
      );
      final generals = _generalsFor(game, 'gp1');
      expect(generals.length, 3);
      expect(generals.where((g) => g.medals == 0).length, 2);
      expect(generals.where((g) => g.id == 'gp1_gen_0').single.medals, 2);
      expect(game.players.single.generalCap, 3);
    });

    test('legacy save without generalCap defaults to derived tech cap', () {
      final game = reconcileGeneralsToGeneralCap(
        _gameWith(
          players: [
            _gp('gp1', tech: {kTechIdNationalism: true}),
          ],
        ),
      );
      expect(game.players.single.generalCap, 4);
      expect(_generalsFor(game, 'gp1').length, 4);
    });

    test('legacy save without generalCap and no tech defaults to 1', () {
      final game = reconcileGeneralsToGeneralCap(
        _gameWith(players: [_gp('gp1')]),
      );
      expect(game.players.single.generalCap, 1);
      expect(_generalsFor(game, 'gp1').length, 1);
    });

    test('roster exceeding persisted cap is retained (never trimmed)', () {
      final game = reconcileGeneralsToGeneralCap(
        _gameWith(
          players: [_gp('gp1', cap: 1)],
          generals: const [
            General(id: 'gp1_gen_0', ownerId: 'gp1', medals: 1),
            General(id: 'gp1_gen_1', ownerId: 'gp1', medals: 2),
            General(id: 'gp1_gen_2', ownerId: 'gp1', medals: 0),
          ],
        ),
      );
      final generals = _generalsFor(game, 'gp1');
      expect(generals.length, 3);
      expect(game.players.single.generalCap, 1);
    });

    test('idempotent when roster already matches cap', () {
      final first = reconcileGeneralsToGeneralCap(
        _gameWith(players: [_gp('gp1', cap: 2)]),
      );
      final second = reconcileGeneralsToGeneralCap(first);
      expect(second.generals.length, first.generals.length);
      expect(identical(second, first), isTrue);
    });
  });

  group('Player.generalCap persistence', () {
    test('round-trips through JSON', () {
      final player = _gp('gp1', cap: 3);
      expect(Player.fromJson(player.toJson()).generalCap, 3);
    });

    test('absent from JSON decodes to null (legacy)', () {
      final json = _gp('gp1').toJson();
      expect(json.containsKey('generalCap'), isFalse);
      expect(Player.fromJson(json).generalCap, isNull);
    });
  });
}
