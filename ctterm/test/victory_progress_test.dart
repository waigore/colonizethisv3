// Tests for VictoryProgressScreen. SPEC/tui/ctterm.md, SPEC/tui/screens/victory-progress.md.

import 'package:ctterm/screens/victory_progress_screen.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:test/test.dart';

void main() {
  group('VictoryProgressScreen (SPEC/tui/screens/victory-progress.md)', () {
    test('can be constructed with required callbacks', () {
      final screen = VictoryProgressScreen(
        onNavigate: (route) {},
        onVictory: () {},
        onDefeat: () {},
      );

      expect(screen.onNavigate, isNotNull);
      expect(screen.onVictory, isNotNull);
      expect(screen.onDefeat, isNotNull);
    });

    test('callbacks are invoked correctly', () {
      var navigateRoute = CttermRoute.mainMenu;
      var victoryCount = 0;
      var defeatCount = 0;

      final screen = VictoryProgressScreen(
        onNavigate: (route) => navigateRoute = route,
        onVictory: () => victoryCount++,
        onDefeat: () => defeatCount++,
      );

      screen.onNavigate(CttermRoute.inGameShell);
      expect(navigateRoute, CttermRoute.inGameShell);

      screen.onVictory();
      expect(victoryCount, 1);

      screen.onDefeat();
      expect(defeatCount, 1);
    });

    test('callback works when multiple invocations', () {
      var navigateCount = 0;
      var victoryCount = 0;
      var defeatCount = 0;

      final screen = VictoryProgressScreen(
        onNavigate: (_) => navigateCount++,
        onVictory: () => victoryCount++,
        onDefeat: () => defeatCount++,
      );

      screen.onNavigate(CttermRoute.pauseOptions);
      screen.onNavigate(CttermRoute.victory);
      screen.onVictory();
      screen.onVictory();
      screen.onDefeat();

      expect(navigateCount, 2);
      expect(victoryCount, 2);
      expect(defeatCount, 1);
    });
  });
}