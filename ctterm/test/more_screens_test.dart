// Tests for more ctterm screens. SPEC/tui/ctterm.md.

import 'package:ctterm/screens/stub_screen.dart';
import 'package:ctterm/screens/generating_world_screen.dart';
import 'package:ctterm/screens/game_setup_screen.dart';
import 'package:ctterm/screens/load_game_screen.dart';
import 'package:test/test.dart';

void main() {
  group('StubScreen (SPEC/tui/ctterm.md)', () {
    test('can be constructed with title', () {
      final screen = StubScreen(title: 'Test Screen');
      expect(screen.title, 'Test Screen');
    });

    test('can be constructed with different titles', () {
      final screen1 = StubScreen(title: 'Units');
      expect(screen1.title, 'Units');

      final screen2 = StubScreen(title: 'Diplomacy');
      expect(screen2.title, 'Diplomacy');
    });
  });

  group('GeneratingWorldScreen (SPEC/tui/screens/generating-world.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = GeneratingWorldScreen(
        onComplete: () {},
        onCancel: () {},
      );

      expect(screen.onComplete, isNotNull);
      expect(screen.onCancel, isNotNull);
      expect(screen.runGeneration, isNull);
    });

    test('callbacks are invoked correctly', () {
      var completeCount = 0;
      var cancelCount = 0;

      final screen = GeneratingWorldScreen(
        onComplete: () => completeCount++,
        onCancel: () => cancelCount++,
      );

      screen.onComplete();
      expect(completeCount, 1);

      screen.onCancel();
      expect(cancelCount, 1);
    });

    test('can be constructed with runGeneration callback', () {
      final screen = GeneratingWorldScreen(
        onComplete: () {},
        onCancel: () {},
        runGeneration: () {},
      );

      expect(screen.runGeneration, isNotNull);
    });
  });

  group('GameSetupScreen (SPEC/tui/screens/game-setup.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = GameSetupScreen(
        onStartGame: (gpIds, leaders) {},
        onBack: () {},
      );

      expect(screen.onStartGame, isNotNull);
      expect(screen.onBack, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var startGpIds = <String>[];
      var startLeaders = <String, String>{};
      var backCount = 0;

      final screen = GameSetupScreen(
        onStartGame: (gpIds, leaders) {
          startGpIds = gpIds;
          startLeaders = leaders;
        },
        onBack: () => backCount++,
      );

      screen.onBack();
      expect(backCount, 1);

      screen.onStartGame(['gp1', 'gp2'], {'gp1': 'leader1'});
      expect(startGpIds, ['gp1', 'gp2']);
      expect(startLeaders['gp1'], 'leader1');
    });
  });

  group('LoadGameScreen (SPEC/tui/screens/load-game.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = LoadGameScreen(
        onLoad: (saveId) {},
        onBack: () {},
        onDelete: (saveId) {},
      );

      expect(screen.onLoad, isNotNull);
      expect(screen.onBack, isNotNull);
      expect(screen.onDelete, isNotNull);
      expect(screen.dataDirOverride, isNull);
    });

    test('callbacks are invoked correctly', () {
      var loadSaveId = '';
      var backCount = 0;
      var deleteSaveId = '';

      final screen = LoadGameScreen(
        onLoad: (saveId) => loadSaveId = saveId,
        onBack: () => backCount++,
        onDelete: (saveId) => deleteSaveId = saveId,
      );

      screen.onLoad('game_001');
      expect(loadSaveId, 'game_001');

      screen.onBack();
      expect(backCount, 1);

      screen.onDelete('game_001');
      expect(deleteSaveId, 'game_001');
    });

    test('can be constructed with dataDirOverride', () {
      final screen = LoadGameScreen(
        onLoad: (saveId) {},
        onBack: () {},
        onDelete: (saveId) {},
        dataDirOverride: '/custom/path',
      );

      expect(screen.dataDirOverride, '/custom/path');
    });
  });
}