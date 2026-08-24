import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/general_cap_test_harness.dart';

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
      final game = syncGeneralCapsFromTech(
        generalCapTestGameWith(players: [generalCapTestGp('gp1')]),
      );
      expect(game.players.single.generalCap, 1);
      final generals = generalCapTestGeneralsFor(game, 'gp1');
      expect(generals.length, 1);
      expect(generals.single.medals, 0);
    });

    test(
      'organised_regiments raises cap to 2 and spawns a 0-medal general',
      () {
        var game = syncGeneralCapsFromTech(
          generalCapTestGameWith(players: [generalCapTestGp('gp1')]),
        );
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
        final generals = generalCapTestGeneralsFor(game, 'gp1');
        expect(generals.length, 2);
        // Existing general (with medals) preserved; the new one starts at 0.
        expect(generals.where((g) => g.medals == 3).length, 1);
        expect(generals.where((g) => g.medals == 0).length, 1);
      },
    );

    test('national_bureaucracy gives cap 3 with three generals', () {
      final game = syncGeneralCapsFromTech(
        generalCapTestGameWith(
          players: [
            generalCapTestGp('gp1', tech: {kTechIdNationalBureaucracy: true}),
          ],
        ),
      );
      expect(game.players.single.generalCap, 3);
      expect(generalCapTestGeneralsFor(game, 'gp1').length, 3);
    });

    test('nationalism gives cap 4 with four generals', () {
      final game = syncGeneralCapsFromTech(
        generalCapTestGameWith(
          players: [
            generalCapTestGp('gp1', tech: {kTechIdNationalism: true}),
          ],
        ),
      );
      expect(game.players.single.generalCap, 4);
      expect(generalCapTestGeneralsFor(game, 'gp1').length, 4);
    });

    test('researching both nb and iit keeps cap at 3 (no stack)', () {
      final game = syncGeneralCapsFromTech(
        generalCapTestGameWith(
          players: [
            generalCapTestGp(
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
      expect(generalCapTestGeneralsFor(game, 'gp1').length, 3);
    });

    test('multiple GPs each get independent caps and unique general ids', () {
      final game = syncGeneralCapsFromTech(
        generalCapTestGameWith(
          players: [
            generalCapTestGp('gp1'),
            generalCapTestGp('gp2', tech: {kTechIdOrganisedRegiments: true}),
          ],
        ),
      );
      expect(game.players[0].generalCap, 1);
      expect(game.players[1].generalCap, 2);
      expect(generalCapTestGeneralsFor(game, 'gp1').length, 1);
      expect(generalCapTestGeneralsFor(game, 'gp2').length, 2);
      final ids = game.generals.map((g) => g.id).toSet();
      expect(ids.length, game.generals.length);
    });
  });
}
