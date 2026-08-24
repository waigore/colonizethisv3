import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/general_cap_test_harness.dart';

void main() {
  group('reconcileGeneralsToGeneralCap (load-time, spawn-only)', () {
    test('persisted cap with short roster spawns missing generals', () {
      final game = reconcileGeneralsToGeneralCap(
        generalCapTestGameWith(
          players: [generalCapTestGp('gp1', cap: 3)],
          generals: const [General(id: 'gp1_gen_0', ownerId: 'gp1', medals: 2)],
        ),
      );
      final generals = generalCapTestGeneralsFor(game, 'gp1');
      expect(generals.length, 3);
      expect(generals.where((g) => g.medals == 0).length, 2);
      expect(generals.where((g) => g.id == 'gp1_gen_0').single.medals, 2);
      expect(game.players.single.generalCap, 3);
    });

    test('legacy save without generalCap defaults to derived tech cap', () {
      final game = reconcileGeneralsToGeneralCap(
        generalCapTestGameWith(
          players: [
            generalCapTestGp('gp1', tech: {kTechIdNationalism: true}),
          ],
        ),
      );
      expect(game.players.single.generalCap, 4);
      expect(generalCapTestGeneralsFor(game, 'gp1').length, 4);
    });

    test('legacy save without generalCap and no tech defaults to 1', () {
      final game = reconcileGeneralsToGeneralCap(
        generalCapTestGameWith(players: [generalCapTestGp('gp1')]),
      );
      expect(game.players.single.generalCap, 1);
      expect(generalCapTestGeneralsFor(game, 'gp1').length, 1);
    });

    test('roster exceeding persisted cap is retained (never trimmed)', () {
      final game = reconcileGeneralsToGeneralCap(
        generalCapTestGameWith(
          players: [generalCapTestGp('gp1', cap: 1)],
          generals: const [
            General(id: 'gp1_gen_0', ownerId: 'gp1', medals: 1),
            General(id: 'gp1_gen_1', ownerId: 'gp1', medals: 2),
            General(id: 'gp1_gen_2', ownerId: 'gp1', medals: 0),
          ],
        ),
      );
      final generals = generalCapTestGeneralsFor(game, 'gp1');
      expect(generals.length, 3);
      expect(game.players.single.generalCap, 1);
    });

    test('idempotent when roster already matches cap', () {
      final first = reconcileGeneralsToGeneralCap(
        generalCapTestGameWith(players: [generalCapTestGp('gp1', cap: 2)]),
      );
      final second = reconcileGeneralsToGeneralCap(first);
      expect(second.generals.length, first.generals.length);
      expect(identical(second, first), isTrue);
    });
  });

  group('Player.generalCap persistence', () {
    test('round-trips through JSON', () {
      final player = generalCapTestGp('gp1', cap: 3);
      expect(Player.fromJson(player.toJson()).generalCap, 3);
    });

    test('absent from JSON decodes to null (legacy)', () {
      final json = generalCapTestGp('gp1').toJson();
      expect(json.containsKey('generalCap'), isFalse);
      expect(Player.fromJson(json).generalCap, isNull);
    });
  });
}
