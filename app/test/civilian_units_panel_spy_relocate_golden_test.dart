// Widget golden coverage for Spy Relocate row chrome on UNIT10001 (Refs #4219).
//
// Pins Relocate action row, Spy-specific status copy (Reserve / Holding intel
// with rival-GP research clause), and editorial-monocle dark chrome.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';
import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _hostViewport = Size(440, 820);

const BoxConstraints _panelConstraints = BoxConstraints(
  maxWidth: 400,
  maxHeight: 760,
);

Widget _host({required Key boundaryKey, required Widget child}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    wrapInProviderScope: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: ConstrainedBox(constraints: _panelConstraints, child: child),
  );
}

void main() {
  suppressLogsForTests();

  Future<void> pumpSpyPanel(
    WidgetTester tester,
    Widget panel,
    Key key,
  ) async {
    await configureGoldenSurface(tester, size: _hostViewport);
    await tester.pumpWidget(_host(boundaryKey: key, child: panel));
    await pumpForGolden(tester);
  }

  testWidgets(
    'golden: UNIT10001 Spy reserve with Relocate (Refs #4219)',
    (WidgetTester tester) async {
      const key = ValueKey('unit_panel_civilian_spy_reserve_golden');
      final game = buildCivilianSpyFixtureGame(id: 'g_spy_golden_reserve');
      await pumpSpyPanel(
        tester,
        CivilianUnitsPanel(
          game: game,
          humanPlayerId: 'h1',
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CivilianUnitsPanel), findsOneWidget);
      expect(find.text('Relocate'), findsOneWidget);
      expect(find.textContaining('Status: Reserve'), findsOneWidget);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/unit_panel_civilian_spy_reserve.png'),
      );
    },
  );

  testWidgets(
    'golden: UNIT10001 Spy holding intel with Relocate (Refs #4219)',
    (WidgetTester tester) async {
      const key = ValueKey('unit_panel_civilian_spy_holding_intel_golden');
      final game = buildCivilianSpyFixtureGame(
        id: 'g_spy_golden_foreign',
        foreignStation: true,
      );
      await pumpSpyPanel(
        tester,
        CivilianUnitsPanel(
          game: game,
          humanPlayerId: 'h1',
          bus: AppEventBus.create(),
        ),
        key,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CivilianUnitsPanel), findsOneWidget);
      expect(find.text('Relocate'), findsOneWidget);
      expect(find.textContaining('Holding intel:'), findsOneWidget);
      expect(find.textContaining('may speed research'), findsOneWidget);
      expectEditorialMonocleDarkChrome(tester);

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/unit_panel_civilian_spy_holding_intel.png'),
      );
    },
  );
}
