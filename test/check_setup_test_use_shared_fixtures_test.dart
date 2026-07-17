import 'package:test/test.dart';

import '../tool/check_setup_test_use_shared_fixtures.dart';

void main() {
  group('setupTestSharedFixturesViolationReason', () {
    const supportPath =
        'packages/colonizethis_setup/test/setup/'
        'init_game_orchestrator_test_support.dart';
    const testPath = 'packages/colonizethis_setup/test/setup/example_test.dart';

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

  group('findSetupTestDuplicateInitRunViolations', () {
    const supportPath =
        'packages/colonizethis_setup/test/setup/'
        'init_game_orchestrator_test_support.dart';
    const testPath = 'packages/colonizethis_setup/test/setup/example_test.dart';

    test('flags identical inline config expressions across test bodies', () {
      final violations = findSetupTestDuplicateInitRunViolations(testPath, '''
void main() {
  test('a', () {
    final result = runInitGame(
      config: configWithOverrides(advancedStart: AdvancedStartType.turns50),
      options: defaultInitOptions,
    );
  });
  test('b', () {
    final result = runInitGame(
      config: configWithOverrides(advancedStart: AdvancedStartType.turns50),
      options: defaultInitOptions,
    );
  });
}
''');
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('sharedInitGameResult'));
      expect(violations.single.message, contains('2 test bodies'));
    });

    test('resolves a once-declared config identifier across bodies', () {
      final violations = findSetupTestDuplicateInitRunViolations(testPath, '''
void main() {
  test('a', () {
    final configA = lockedFullInitConfig(seed: 42);
    final result = runInitGame(config: configA, options: defaultInitOptions);
  });
  test('b', () {
    final result = runInitGame(
      config: lockedFullInitConfig(seed: 42),
      options: defaultInitOptions,
    );
  });
}
''');
      expect(violations, hasLength(1));
    });

    test('does not flag a determinism double run in one test body', () {
      final violations = findSetupTestDuplicateInitRunViolations(testPath, '''
void main() {
  test('deterministic', () {
    final config = configWithOverrides(seed: 900_002);
    final first = runInitGame(config: config, options: defaultInitOptions);
    final second = runInitGame(config: config, options: defaultInitOptions);
  });
}
''');
      expect(violations, isEmpty);
    });

    test('does not group unrelated locals sharing the `config` name', () {
      final violations = findSetupTestDuplicateInitRunViolations(testPath, '''
void main() {
  test('a', () {
    final config = configWithOverrides(seed: 1);
    final result = runInitGame(config: config, options: defaultInitOptions);
  });
  test('b', () {
    final config = configWithOverrides(seed: 2);
    final result = runInitGame(config: config, options: defaultInitOptions);
  });
}
''');
      expect(violations, isEmpty);
    });

    test('skips calls with custom options or extra arguments', () {
      final violations = findSetupTestDuplicateInitRunViolations(testPath, '''
void main() {
  test('a', () {
    final result = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: const InitGameOptions(cellSize: 8, renderPng: true),
    );
  });
  test('b', () {
    final result = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: const InitGameOptions(cellSize: 8, renderPng: true),
    );
  });
  test('c', () {
    final result = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: defaultInitOptions,
      generateRegion: myGenerator,
    );
  });
  test('d', () {
    final result = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: defaultInitOptions,
      generateRegion: myGenerator,
    );
  });
}
''');
      expect(violations, isEmpty);
    });

    test('the orchestrator support file is exempt', () {
      final violations = findSetupTestDuplicateInitRunViolations(
        supportPath,
        '''
InitGameResult a() =>
    runInitGame(config: GameSetupConfig.defaultConfig, options: defaultInitOptions);
InitGameResult b() =>
    runInitGame(config: GameSetupConfig.defaultConfig, options: defaultInitOptions);
''',
      );
      expect(violations, isEmpty);
    });
  });
}
