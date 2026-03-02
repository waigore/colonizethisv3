// Tests for victory and defeat screens. SPEC/tui/ctterm.md, SPEC/game/victory.md.

import 'package:ctterm/screens/victory_screen.dart';
import 'package:ctterm/screens/defeat_screen.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:test/test.dart';

void main() {
  group('VictoryScreen (SPEC/tui/ctterm.md)', () {
    test('can be constructed with required parameters', () {
      final screen = VictoryScreen(
        onNavigate: (route) {},
        onExitToMainMenu: () {},
        victoryType: 'Military',
        turnNumber: 42,
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.onExitToMainMenu, isNotNull);
      expect(screen.victoryType, 'Military');
      expect(screen.turnNumber, 42);
      expect(screen.winnerName, 'You');
    });

    test('can be constructed with custom winner name', () {
      final screen = VictoryScreen(
        onNavigate: (route) {},
        onExitToMainMenu: () {},
        victoryType: 'Economic',
        turnNumber: 100,
        winnerName: 'Player 1',
      );

      expect(screen.winnerName, 'Player 1');
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      var exitCount = 0;

      final screen = VictoryScreen(
        onNavigate: (route) => navigateRoute = route,
        onExitToMainMenu: () => exitCount++,
        victoryType: 'Military',
        turnNumber: 42,
      );

      screen.onNavigate(CttermRoute.mainMenu);
      expect(navigateRoute, CttermRoute.mainMenu);

      screen.onExitToMainMenu();
      expect(exitCount, 1);
    });
  });

  group('DefeatScreen (SPEC/tui/ctterm.md)', () {
    test('can be constructed with required parameters', () {
      final screen = DefeatScreen(
        onNavigate: (route) {},
        onExitToMainMenu: () {},
        winnerName: 'England',
        victoryType: 'Military',
        turnNumber: 50,
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.onExitToMainMenu, isNotNull);
      expect(screen.winnerName, 'England');
      expect(screen.victoryType, 'Military');
      expect(screen.turnNumber, 50);
      expect(screen.finalStandings, isEmpty);
    });

    test('can be constructed with final standings', () {
      final standings = [
        const MapEntry('England', 35),
        const MapEntry('France', 28),
        const MapEntry('Spain', 15),
      ];

      final screen = DefeatScreen(
        onNavigate: (route) {},
        onExitToMainMenu: () {},
        winnerName: 'England',
        victoryType: 'Military',
        turnNumber: 50,
        finalStandings: standings,
      );

      expect(screen.finalStandings.length, 3);
      expect(screen.finalStandings[0].key, 'England');
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      var exitCount = 0;

      final screen = DefeatScreen(
        onNavigate: (route) => navigateRoute = route,
        onExitToMainMenu: () => exitCount++,
        winnerName: 'England',
        victoryType: 'Military',
        turnNumber: 50,
      );

      screen.onNavigate(CttermRoute.mapContext);
      expect(navigateRoute, CttermRoute.mapContext);

      screen.onExitToMainMenu();
      expect(exitCount, 1);
    });
  });
}