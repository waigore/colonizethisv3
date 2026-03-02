// Tests for pause options and settings screens. SPEC/tui/ctterm.md.

import 'package:ctterm/screens/pause_options_screen.dart';
import 'package:ctterm/screens/settings_screen.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:test/test.dart';

void main() {
  group('PauseOptionsScreen (SPEC/tui/screens/pause-options.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = PauseOptionsScreen(
        onNavigate: (route) {},
        onExitToMainMenu: () {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.onExitToMainMenu, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      var exitCount = 0;

      final screen = PauseOptionsScreen(
        onNavigate: (route) => navigateRoute = route,
        onExitToMainMenu: () => exitCount++,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onExitToMainMenu();
      expect(exitCount, 1);
    });
  });

  group('SettingsScreen (SPEC/tui/screens/settings.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = SettingsScreen(
        onBack: () {},
        initialTheme: TerminalTheme.dark,
      );

      expect(screen.onBack, isNotNull);
      expect(screen.initialTheme, TerminalTheme.dark);
      expect(screen.onThemeChanged, isNull);
    });

    test('callbacks are invoked correctly', () {
      var backCount = 0;
      var changedTheme = TerminalTheme.dark;

      final screen = SettingsScreen(
        onBack: () => backCount++,
        initialTheme: TerminalTheme.dark,
        onThemeChanged: (theme) => changedTheme = theme,
      );

      screen.onBack();
      expect(backCount, 1);

      // Test that onThemeChanged can be called when provided
      screen.onThemeChanged?.call(TerminalTheme.light);
      expect(changedTheme, TerminalTheme.light);
    });

    test('can be constructed with light theme', () {
      final screen = SettingsScreen(
        onBack: () {},
        initialTheme: TerminalTheme.light,
      );

      expect(screen.initialTheme, TerminalTheme.light);
    });
  });
}