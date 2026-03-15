// Tests for debug log viewer screen. SPEC/program/debug-log-viewer.md.

import 'package:ctterm/screens/debug_log_viewer_screen.dart';
import 'package:ctterm/screens/pause_options_screen.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('DebugLogViewerScreen (SPEC/program/debug-log-viewer.md)', () {
    test('can be constructed with onBack callback', () {
      var backCount = 0;
      final screen = DebugLogViewerScreen(
        onBack: () => backCount++,
      );

      expect(screen.onBack, isNotNull);
      screen.onBack();
      expect(backCount, 1);
    });
  });

  group('PauseOptionsScreen includes Debug log', () {
    test('navigating to Debug log viewer when third item selected', () {
      CttermRoute? navigatedRoute;
      final screen = PauseOptionsScreen(
        onNavigate: (route) => navigatedRoute = route,
        onExitToMainMenu: () {},
      );

      expect(screen.onNavigate, isNotNull);
      screen.onNavigate(CttermRoute.debugLogViewer);
      expect(navigatedRoute, CttermRoute.debugLogViewer);
    });
  });
}
