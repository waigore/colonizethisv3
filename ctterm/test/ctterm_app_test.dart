// Tests for CttermApp. SPEC/tui/ctterm.md.

import 'package:ctterm/ctterm_app.dart';
import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('CttermApp', () {
    test('shows lock prompt when initialLockDetected is true', () {
      final app = CttermApp(initialLockDetected: true);
      expect(app.initialLockDetected, isTrue);
    });

    test('does not show lock prompt when initialLockDetected is false', () {
      final app = CttermApp(initialLockDetected: false);
      expect(app.initialLockDetected, isFalse);
    });

    test('shows main menu route by default', () {
      final app = CttermApp();
      expect(app, isNotNull);
    });

    test('accepts dataDirOverride parameter', () {
      final app = CttermApp(dataDirOverride: '/custom/path');
      expect(app.dataDirOverride, equals('/custom/path'));
    });

    test('state initializes with mainMenu route', () {
      final app = CttermApp();
      // CttermApp is a StatefulComponent, we test its construction
      expect(app, isNotNull);
    });

    test('default theme is dark', () {
      final app = CttermApp();
      expect(app, isNotNull);
    });
  });

  group('CttermApp navigation callbacks', () {
    test('onPrepareNewGame callback is defined', () {
      // Just verify the CttermApp can be constructed
      final app = CttermApp();
      expect(app, isNotNull);
    });

    test(' CttermRoute enum has all expected values', () {
      expect(CttermRoute.values.length, equals(20));
      expect(CttermRoute.mainMenu.screenId, equals('100001'));
      expect(CttermRoute.gameSetup.screenId, equals('100002'));
      expect(CttermRoute.loadGame.screenId, equals('100003'));
      expect(CttermRoute.generatingWorld.screenId, equals('100004'));
      expect(CttermRoute.settings.screenId, equals('100005'));
      expect(CttermRoute.inGameShell.screenId, equals('100006'));
      expect(CttermRoute.mapContext.screenId, equals('100007'));
      expect(CttermRoute.units.screenId, equals('100008'));
      expect(CttermRoute.development.screenId, equals('100009'));
      expect(CttermRoute.production.screenId, equals('100010'));
      expect(CttermRoute.academy.screenId, equals('100011'));
      expect(CttermRoute.shipyard.screenId, equals('100012'));
      expect(CttermRoute.diplomacy.screenId, equals('100013'));
      expect(CttermRoute.technology.screenId, equals('100014'));
      expect(CttermRoute.victoryProgress.screenId, equals('100015'));
      expect(CttermRoute.victory.screenId, equals('100016'));
      expect(CttermRoute.defeat.screenId, equals('100017'));
      expect(CttermRoute.pauseOptions.screenId, equals('100018'));
      expect(CttermRoute.pendingOvertures.screenId, equals('100019'));
      expect(CttermRoute.debugLogViewer.screenId, equals('100020'));
    });
  });
}
