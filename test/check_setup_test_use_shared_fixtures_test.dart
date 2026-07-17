import 'package:test/test.dart';

import '../tool/check_setup_test_use_shared_fixtures.dart';

void main() {
  group('setupTestSharedFixturesViolationReason', () {
    const supportPath =
        'packages/colonizethis_setup/test/setup/'
        'init_game_orchestrator_test_support.dart';
    const testPath =
        'packages/colonizethis_setup/test/setup/example_test.dart';

    test('passes when test uses TestFixtures and configWithOverrides', () {
      expect(
        setupTestSharedFixturesViolationReason(testPath, '''
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  final game = TestFixtures.minimalGame(id: 'g1', turnNumber: 0, players: const []);
  final config = configWithOverrides(advancedStart: AdvancedStartType.turns50);
}
'''),
        isNull,
      );
    });

    test('allows GameSetupConfig constructor inside orchestrator support', () {
      expect(
        setupTestSharedFixturesViolationReason(supportPath, '''
GameSetupConfig configWithOverrides() {
  return GameSetupConfig(seed: 1);
}
'''),
        isNull,
      );
    });

    test('flags GameSetupConfig rebuild in a _test.dart file', () {
      final reason = setupTestSharedFixturesViolationReason(testPath, '''
void main() {
  final config = GameSetupConfig(advancedStart: AdvancedStartType.turns50);
}
''');
      expect(reason, isNotNull);
      expect(reason!, contains('GameSetupConfig'));
    });

    test('flags empty Game shell in a _test.dart file', () {
      final reason = setupTestSharedFixturesViolationReason(testPath, '''
void main() {
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [],
  );
}
''');
      expect(reason, isNotNull);
      expect(reason!, contains('Game(...)'));
      expect(reason, contains('WorldState(...)'));
    });

    test('ignores GameSetupConfig mentions in full-line comments', () {
      expect(
        setupTestSharedFixturesViolationReason(testPath, '''
// final config = GameSetupConfig(seed: 1);
void main() {}
'''),
        isNull,
      );
    });

    test('out-of-scope paths are ignored', () {
      expect(
        setupTestSharedFixturesViolationReason(
          'packages/colonizethis_logic/test/example_test.dart',
          'final g = Game(id: "x", worldState: WorldState(), players: const []);',
        ),
        isNull,
      );
    });
  });
}
