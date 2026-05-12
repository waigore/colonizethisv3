import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/fleet_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'e2e_test_shared.dart';
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

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    final bootstrapSw = Stopwatch()..start();
    await bootstrapForIntegrationTest();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    perf.timing('bootstrap_for_integration_test', bootstrapSw.elapsed);
    final preloadSw = Stopwatch()..start();
    await e2eEnsureRelocated64pxPngDecode(
      <String>{
        ...kCivilianIconSlugs.map(
          (slug) => 'assets/icons/64/ui_icon_civ_$slug.png',
        ),
        ...kResourceIconIds.map(
          (resourceId) => 'assets/icons/64/ui_icon_com_$resourceId.png',
        ),
        ...kTownIconIds.map((iconId) => 'assets/icons/64/ui_icon_com_$iconId.png'),
        ...kProvinceLabelIconIds.map(
          (iconId) => 'assets/icons/64/ui_icon_$iconId.png',
        ),
        kFleetMapIcon64PngAssetPath,
      },
    );
    perf.timing('asset_preload', preloadSw.elapsed);

    final newGameToMapSw = Stopwatch()..start();
    await e2eBootstrapNewGameToMap(tester, perf: perf);
    perf.timing('new_game_to_map', newGameToMapSw.elapsed);

    await tester.tap(find.byKey(kHomeToCapitalButtonKey));
    await e2ePumpFor(tester, const Duration(seconds: 1));

    expect(find.byKey(kCtE2EOpenCapitalProvinceDetailKey), findsOneWidget);
    await tester.tap(find.byKey(kCtE2EOpenCapitalProvinceDetailKey));

    await e2eWaitUntilFound(
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
    e2eCollectTextPreorder(
      tester.element(find.byKey(kCtE2EProvincePanelRootKey)),
      actual,
    );
    expect(actual, orderedEquals(expected));
    perf.timing('test_total', testSw.elapsed);
  });
}
