import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('kHiddenAgendaIds', () {
    test('contains expected agenda ids', () {
      expect(kHiddenAgendaIds, contains('warmonger'));
      expect(kHiddenAgendaIds, contains('peacemaker'));
      expect(kHiddenAgendaIds, contains('backstabber'));
      expect(kHiddenAgendaIds, contains('isolationist'));
      expect(kHiddenAgendaIds.length, 6);
    });
  });

  group('assignHiddenAgendasForGame', () {
    test('empty players returns game unchanged', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        players: const [],
      );
      final out = assignHiddenAgendasForGame(game);
      expect(out.hiddenAgendaByGpId, isEmpty);
    });

    test('human-only players do not get agendas', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
      ).copyWith(aiControlByGpId: const {'gp1': false});
      final out = assignHiddenAgendasForGame(game);
      expect(out.hiddenAgendaByGpId, isEmpty);
    });

    test('AI players get agendas from kHiddenAgendaIds', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
      ).copyWith(
        globalGameSeed: 42,
        aiSeedByGpId: const {'gp1': 100},
      );
      final out = assignHiddenAgendasForGame(game);
      expect(out.hiddenAgendaByGpId.length, 1);
      expect(kHiddenAgendaIds, contains(out.hiddenAgendaByGpId['gp1']));
    });
  });
}
