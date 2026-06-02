import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'e2e_helpers.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game → capital province panel matches model (wide layout)', (
    WidgetTester tester,
  ) async {
    // Standard E2E scenario opener (kCtE2EEnabled gate, surface size,
    // bootstrap, asset preload, new-game-to-map, l10n) lifted into
    // [enterStandardE2eScenario] so the full-turn and capital-panel
    // scenarios share one canonical entry sequence. The legacy
    // capital-panel inline opener did not time the asset-preload slice;
    // passing `assetPreloadTimingPhase: null` preserves byte-identical
    // emitted-log behaviour across the lift (no new `asset_preload`
    // `E2E_TIMING` line). Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
    final opener = await enterStandardE2eScenario(
      tester,
      testName: 'new_game_capital_panel',
      bootstrapForIntegrationTest: bootstrapForIntegrationTest,
      assetPreloadTimingPhase: null,
    );
    final perf = opener.perf;
    final testSw = opener.testSw;
    final l10n = opener.l10n;
    final ensureUnderWallClock = opener.ensureUnderWallClock;

    // Replaces the legacy raw `tester.tap(find.byKey(...))` taps with the
    // shared defensive `ensureVisible` + `hitTestable` resolve recipe so a
    // transient overlay or surface clip cannot silently drop the home/marker
    // tap on a small viewport. The helper is the same primitive the panel
    // openers consume via `e2eEnsureVisibleAndTapHitTestable` (Refs GitHub
    // #2336 AC10 / e2e-ui-stability rule — verify visibility before
    // interaction).
    await ensureVisibleAndTapHitTestable(
      tester,
      find.byKey(kHomeToCapitalButtonKey),
    );
    await waitUntilFound(
      tester,
      find.byKey(kCtE2EOpenCapitalProvinceDetailKey).hitTestable(),
      timeout: const Duration(seconds: 30),
      perf: perf,
      phaseName: 'wait_capital_detail_marker_after_home_tap',
    );

    expect(find.byKey(kCtE2EOpenCapitalProvinceDetailKey), findsOneWidget);
    await ensureVisibleAndTapHitTestable(
      tester,
      find.byKey(kCtE2EOpenCapitalProvinceDetailKey),
    );

    // Pre-lift this was an inline `expectPanelTextsMatchSnapshot` call with
    // an explicit 30s timeout and the `open_panel_province` phase label;
    // both are captured byte-identically by
    // `expectProvincePanelMatchesE2eSnapshot` (Refs GitHub #2336 AC1 / AC2 /
    // Bottleneck 6).
    await expectProvincePanelMatchesE2eSnapshot(tester, l10n, perf: perf);

    expect(find.byKey(kCtE2EProvincePanelRootKey), findsOneWidget);
    ensureUnderWallClock('test complete');
    perf.timing('test_total', testSw.elapsed);
  });
}
