import 'package:colonizethis_app/config/desktop_window_settings.dart';
import 'package:colonizethis_app/core/services/desktop_window_startup_service.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('DesktopWindowState.fromSettingsValue', () {
    test('parses valid state map', () {
      final parsed = DesktopWindowState.fromSettingsValue(const {
        'x': 10,
        'y': 20,
        'width': 1280,
        'height': 720,
        'maximized': false,
      });

      expect(parsed, isNotNull);
      expect(parsed!.width, 1280);
      expect(parsed.height, 720);
      expect(parsed.maximized, isFalse);
    });

    test('returns null for malformed payload', () {
      final parsed = DesktopWindowState.fromSettingsValue(const {
        'x': 10,
        'y': 20,
        'width': 640,
        'height': 300,
        'maximized': 'yes',
      });

      expect(parsed, isNull);
    });
  });

  group('DesktopStartupDecision.resolve', () {
    test('restore state wins over maximize preference', () {
      const state = DesktopWindowState(
        x: 0,
        y: 0,
        width: 1280,
        height: 720,
        maximized: false,
      );
      final decision = DesktopStartupDecision.resolve(
        restoreState: state,
        startupMaximized: true,
      );

      expect(decision.mode, DesktopStartupMode.restoreState);
      expect(decision.restoreState, state);
    });

    test('falls back to maximize when no restore state', () {
      final decision = DesktopStartupDecision.resolve(
        restoreState: null,
        startupMaximized: true,
      );

      expect(decision.mode, DesktopStartupMode.maximize);
      expect(decision.restoreState, isNull);
    });

    test('falls back to default size when maximize preference is disabled', () {
      final decision = DesktopStartupDecision.resolve(
        restoreState: null,
        startupMaximized: false,
      );

      expect(decision.mode, DesktopStartupMode.defaultSize);
      expect(decision.restoreState, isNull);
    });
  });
}
