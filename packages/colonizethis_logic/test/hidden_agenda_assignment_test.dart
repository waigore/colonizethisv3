import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/setup/hidden_agenda_assignment.dart';
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
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      );
      final out = assignHiddenAgendasForGame(game);
      expect(out.hiddenAgendaByGpId, isEmpty);
    });

    test('human-only players do not get agendas', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
        aiControlByGpId: const {'gp1': false},
      );
      final out = assignHiddenAgendasForGame(game);
      expect(out.hiddenAgendaByGpId, isEmpty);
    });

    test('AI players get agendas from kHiddenAgendaIds', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
        globalGameSeed: 42,
        aiSeedByGpId: const {'gp1': 100},
      );
      final out = assignHiddenAgendasForGame(game);
      expect(out.hiddenAgendaByGpId.length, 1);
      expect(kHiddenAgendaIds, contains(out.hiddenAgendaByGpId['gp1']));
    });
  });
}
