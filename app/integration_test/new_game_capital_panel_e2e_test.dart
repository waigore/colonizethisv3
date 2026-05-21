import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'e2e_helpers.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_app/test_support/province_panel_e2e_expected_lines.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game → capital province panel matches model (wide layout)', (
    WidgetTester tester,
  ) async {
    const testName = 'new_game_capital_panel';
    final perf = E2ePerfLog(testName);
    final testSw = Stopwatch()..start();
    expect(
      kCtE2EEnabled,
      isTrue,
      reason:
          'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
    );

    // 5-minute PR wall-clock cap per scenario path per
    // `SPEC/program/e2e-integration-tests.md` § Determinism PR runtime rule
    // (`colonizethis-e2e-ui-stability.mdc`). Mirrors the fleet E2E pattern;
    // Refs GitHub #2336.
    final ensureUnderWallClock = e2eMakeWallClockGuard(
      testName: testName,
      stopwatch: testSw,
    );

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    final bootstrapSw = Stopwatch()..start();
    await bootstrapForIntegrationTest();
    await tester.pump();
    await e2eWaitForNewGameEntry(tester, perf: perf);
    perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
    ensureUnderWallClock('after bootstrap_for_integration_test');
    await ensureAllRelocated64pxPngsLoadSuiteOnce();
    ensureUnderWallClock('after asset_preload');

    final newGameToMapSw = Stopwatch()..start();
    await bootstrapNewGameToMap(tester, perf: perf);
    perf.timing('new_game_to_map', newGameToMapSw.elapsed);
    ensureUnderWallClock('after new_game_to_map');

    await tester.tap(find.byKey(kHomeToCapitalButtonKey));
    await waitUntilFound(
      tester,
      find.byKey(kCtE2EOpenCapitalProvinceDetailKey).hitTestable(),
      timeout: const Duration(seconds: 30),
      perf: perf,
      phaseName: 'wait_capital_detail_marker_after_home_tap',
    );

    expect(find.byKey(kCtE2EOpenCapitalProvinceDetailKey), findsOneWidget);
    await tester.tap(find.byKey(kCtE2EOpenCapitalProvinceDetailKey));

    await waitUntilFound(
      tester,
      find.byKey(kCtE2EProvincePanelRootKey),
      timeout: const Duration(seconds: 30),
      perf: perf,
      phaseName: 'open_panel_province',
    );

    expect(find.byKey(kCtE2EProvincePanelRootKey), findsOneWidget);

    final snap = ctE2eLastPanelSnapshot;
    expect(snap, isNotNull);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final expected = provincePanelWideLayoutExpectedTexts(snap!, l10n);

    final actual = <String>[];
    collectTextPreorder(
      tester.element(find.byKey(kCtE2EProvincePanelRootKey)),
      actual,
    );
    expect(actual, orderedEquals(expected));
    ensureUnderWallClock('test complete');
    perf.timing('test_total', testSw.elapsed);
  });
}
