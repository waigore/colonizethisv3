// Tests for MainMenuScreen. SPEC/tui/ctterm.md, SPEC/ui/main-menu.md.

import 'package:ctterm/screens/main_menu_screen.dart';
import 'package:test/test.dart';

void main() {
  group('MainMenuScreen (SPEC/tui/ctterm.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = MainMenuScreen(
        onNewGame: () {},
        onLoadGame: () {},
        onSettings: () {},
        onQuit: () {},
      );

      expect(screen.onNewGame, isNotNull);
      expect(screen.onLoadGame, isNotNull);
      expect(screen.onSettings, isNotNull);
      expect(screen.onQuit, isNotNull);
      expect(screen.dataDirOverride, isNull);
    });

    test('can be constructed with dataDirOverride', () {
      final screen = MainMenuScreen(
        onNewGame: () {},
        onLoadGame: () {},
        onSettings: () {},
        onQuit: () {},
        dataDirOverride: '/custom/path',
      );

      expect(screen.dataDirOverride, '/custom/path');
    });

    test('callbacks are invoked correctly', () {
      var newGameCount = 0;
      var loadGameCount = 0;
      var settingsCount = 0;
      var quitCount = 0;

      final screen = MainMenuScreen(
        onNewGame: () => newGameCount++,
        onLoadGame: () => loadGameCount++,
        onSettings: () => settingsCount++,
        onQuit: () => quitCount++,
      );

      screen.onNewGame();
      expect(newGameCount, 1);

      screen.onLoadGame();
      expect(loadGameCount, 1);

      screen.onSettings();
      expect(settingsCount, 1);

      screen.onQuit();
      expect(quitCount, 1);
    });
  });
}