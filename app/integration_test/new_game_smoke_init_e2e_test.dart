import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/main.dart' show bootstrapForIntegrationTest;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';

/// Fast PR quality-gate smoke for the critical first-user-action path:
/// main menu **New Game** → default leaders → **Start** → interactive game
/// screen. "Game has begun" is defined (per #3465 AC) as the
/// [kHomeToCapitalButtonKey] being **clickable**: the smoke locates it and taps
/// it via the proven `ensureVisibleAndTapHitTestable` probe (hit-testable +
/// actually tappable). That button is a Flutter overlay control on top of the
/// Flame layer, so it is hit-testable on the headless xvfb CI runner; the
/// post-tap capital-tile InkWell is rendered *inside* the Flame GL canvas and is
/// intentionally **not** asserted here because GL tile hit-testing is not
/// reliably available on the headless quality-CI runner — clickability of the
/// home→capital button is the AC-defined "game begun" signal.
///
/// Unlike the three `new_game_*_e2e_test.dart` scenarios (which exercise
/// longer flows and are not run in PR quality), this smoke is wired into a
/// dedicated, unconditionally-required `quality.yml` job so any change to the
/// app or its dependent setup/map/logic packages that regresses the init UX
/// fails fast on every PR. Refs GitHub #3465; SPEC
/// `SPEC/program/e2e-integration-tests.md` § CI. Screen IDs exercised:
/// SHEL10002 (main menu), DLG10001 (leader selection), SHEL20001 (game setup),
/// SHEL30001 (game initializing), OVL10001 (game start intro), GAME10001
/// (game screen).
///
/// The 20 s budget is enforced via the existing [e2eMakeWallClockGuard] /
/// `ensureUnderWallClock` machinery and is measured **from after asset
/// preload** (the bootstrap and 64 px PNG decode windows are excluded so CI
/// asset-cache warmth does not eat into the init-path budget), per the issue
/// confirmation. The test file itself is the source of the 20 s enforcement
/// so failures are fast and attributable (`E2E_TIMING` / `E2E_COUNTER`).
const Duration kNewGameSmokeInitBudget = Duration(seconds: 20);

/// Stable test identifier forwarded into [E2ePerfLog] so the smoke's
/// `E2E_TIMING|test=new_game_smoke_init|...` markers are attributable.
const String kNewGameSmokeInitTestName = 'new_game_smoke_init';

void main() {
  suppressLogsForTests();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'new game → default leaders → begin reaches a clickable home→capital '
    'button within the 20s init budget',
    (WidgetTester tester) async {
      // Bootstrap-through-`New Game`-entry (kCtE2EEnabled gate, surface size,
      // bootstrapForIntegrationTest, first pump, wait-for-New-Game-entry).
      // The returned `testSw` covers the full span for the closing
      // `test_total` slice; the 20 s budget below uses a separate stopwatch
      // started after asset preload.
      final bootstrap = await runIntegrationTestBootstrap(
        tester,
        testName: kNewGameSmokeInitTestName,
        bootstrapForIntegrationTest: bootstrapForIntegrationTest,
      );
      final perf = bootstrap.perf;
      final testSw = bootstrap.testSw;

      // Warm the relocated 64 px PNG manifest decode (at most once per VM)
      // before starting the init-path budget so CI asset-cache warmth does
      // not count against the 20 s window.
      await ensureAllRelocated64pxPngsLoadSuiteOnce();

      // Start the tight 20 s init-path budget *after* assets are loaded
      // (Refs #3465). The guard fails fast with an attributable
      // `<testName> exceeded ... wall clock at <step>` message if any
      // checkpoint exceeds the cap.
      final budgetSw = Stopwatch()..start();
      final ensureUnderInitBudget = e2eMakeWallClockGuard(
        testName: kNewGameSmokeInitTestName,
        stopwatch: budgetSw,
        cap: kNewGameSmokeInitBudget,
      );

      // Drive New Game → default leaders → Start → map HUD via the shared
      // bootstrap so the smoke reuses the proven deterministic locators and
      // intro-dismissal path. The helper emits its own `E2E_TIMING` slices
      // (including `wait_for_map_hud_after_new_game_start` with `result=...`
      // attribution) so a slow or failed init is fast to diagnose.
      await bootstrapNewGameToMap(tester, perf: perf);
      ensureUnderInitBudget('after new_game_to_map');

      // "Game has begun" = the home→capital button is clickable (#3465 AC).
      // The button is a Flutter overlay map-corner control layered above the
      // Flame canvas, so we use the proven `ensureVisibleAndTapHitTestable`
      // probe (hit-testable + actually tappable) — the AC's sanctioned
      // "equivalent probe that would actually succeed if tapped" — rather than
      // a raw `.hitTestable()` finder. We deliberately do not assert any
      // post-tap Flame-canvas reaction (e.g. the capital-tile InkWell), since
      // GL tile hit-testing is not reliably available on the headless xvfb
      // quality-CI runner; the button's clickability is the canonical,
      // CI-robust "game begun" signal.
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
      final tapped = await ensureVisibleAndTapHitTestable(
        tester,
        find.byKey(kHomeToCapitalButtonKey),
      );
      expect(
        tapped,
        isTrue,
        reason: 'home→capital button was not clickable (hit-testable + '
            'tappable) after reaching the map HUD',
      );

      ensureUnderInitBudget('test complete');
      perf.timing('test_total', testSw.elapsed);
      perf.timing(
        'init_path_after_asset_preload',
        budgetSw.elapsed,
        meta: 'budget_ms=${kNewGameSmokeInitBudget.inMilliseconds}',
      );
    },
  );
}
