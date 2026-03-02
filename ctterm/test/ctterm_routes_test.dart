// Tests for ctterm routes. SPEC/tui/ctterm.md § Screen IDs.

import 'package:ctterm/ctterm_routes.dart';
import 'package:test/test.dart';

void main() {
  group('CttermRoute screen IDs (SPEC/tui/ctterm.md § Screen IDs)', () {
    test('mainMenu has correct screen ID', () {
      expect(CttermRoute.mainMenu.screenId, '100001');
    });

    test('gameSetup has correct screen ID', () {
      expect(CttermRoute.gameSetup.screenId, '100002');
    });

    test('loadGame has correct screen ID', () {
      expect(CttermRoute.loadGame.screenId, '100003');
    });

    test('generatingWorld has correct screen ID', () {
      expect(CttermRoute.generatingWorld.screenId, '100004');
    });

    test('settings has correct screen ID', () {
      expect(CttermRoute.settings.screenId, '100005');
    });

    test('inGameShell has correct screen ID', () {
      expect(CttermRoute.inGameShell.screenId, '100006');
    });

    test('mapContext has correct screen ID', () {
      expect(CttermRoute.mapContext.screenId, '100007');
    });

    test('units has correct screen ID', () {
      expect(CttermRoute.units.screenId, '100008');
    });

    test('development has correct screen ID', () {
      expect(CttermRoute.development.screenId, '100009');
    });

    test('production has correct screen ID', () {
      expect(CttermRoute.production.screenId, '100010');
    });

    test('academy has correct screen ID', () {
      expect(CttermRoute.academy.screenId, '100011');
    });

    test('shipyard has correct screen ID', () {
      expect(CttermRoute.shipyard.screenId, '100012');
    });

    test('diplomacy has correct screen ID', () {
      expect(CttermRoute.diplomacy.screenId, '100013');
    });

    test('technology has correct screen ID', () {
      expect(CttermRoute.technology.screenId, '100014');
    });

    test('victoryProgress has correct screen ID', () {
      expect(CttermRoute.victoryProgress.screenId, '100015');
    });

    test('victory has correct screen ID', () {
      expect(CttermRoute.victory.screenId, '100016');
    });

    test('defeat has correct screen ID', () {
      expect(CttermRoute.defeat.screenId, '100017');
    });

    test('pauseOptions has correct screen ID', () {
      expect(CttermRoute.pauseOptions.screenId, '100018');
    });

    test('all routes have unique screen IDs', () {
      final screenIds = CttermRoute.values.map((r) => r.screenId).toSet();
      expect(screenIds.length, CttermRoute.values.length);
    });

    test('all screen IDs are 6 digits', () {
      for (final route in CttermRoute.values) {
        expect(route.screenId.length, 6);
        expect(int.tryParse(route.screenId), isNotNull);
      }
    });
  });
}