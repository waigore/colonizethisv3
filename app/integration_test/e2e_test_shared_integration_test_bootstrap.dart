import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default surface size set by [e2eRunIntegrationTestBootstrap] before
/// invoking the injected `bootstrapForIntegrationTest`.
///
/// Mirrors the pre-lift `await tester.binding.setSurfaceSize(const
/// Size(1280, 720))` literal both the standard scenario opener
/// ([e2eEnterStandardE2eScenario]) and the fleet reach preamble
/// ([e2eEnterFleetReachScenarioReady]) inlined verbatim before this lift.
/// A silent drift here would change Flame viewport sizing under every E2E
/// scenario and invalidate visibility-based locators downstream. Refs
/// GitHub #2336 AC1 / AC2 / Bottleneck 6.
const Size kE2eDefaultIntegrationTestBootstrapSurfaceSize = Size(1280, 720);

/// Default `E2E_TIMING|...|phase=...` label emitted by
/// [e2eRunIntegrationTestBootstrap] for the
/// `bootstrapForIntegrationTest` + first-pump + [e2eWaitForNewGameEntry]
/// window.
///
/// Preserves the pre-lift `perf.timing('bootstrap_for_integration_test',
/// bootstrapSw.elapsed)` literal that both [e2eEnterStandardE2eScenario]
/// and [e2eEnterFleetReachScenarioReady] emitted from their inline blocks.
/// Downstream `E2E_TIMING|...|phase=bootstrap_for_integration_test` log
/// scrapers and AC8 dashboards key on this exact literal; a silent rename
/// would orphan every dashboard tracking the pre-`New Game`-entry boot
/// cost. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
const String kE2eDefaultIntegrationTestBootstrapTimingPhase =
    'bootstrap_for_integration_test';

/// Result of [e2eRunIntegrationTestBootstrap].
///
/// Carries the two handles every standard / fleet `testWidgets` preamble
/// needs to continue the scenario after the
/// `bootstrapForIntegrationTest` → first-pump → [e2eWaitForNewGameEntry]
/// → bootstrap-timing-slice sequence:
///
/// - [perf]: scenario-scoped [E2ePerfLog] (test name forwarded from the
///   helper's `testName` argument). The helper emits the
///   `bootstrap_for_integration_test` slice (default phase
///   [kE2eDefaultIntegrationTestBootstrapTimingPhase]) into this log
///   before returning; downstream phases continue to drive
///   asset preload / new-game-to-map / panel-open / advance-turn helpers
///   against the same log so the `E2E_TIMING|test=<testName>|...`
///   attribution stays stable across the scenario.
/// - [testSw]: wall-clock stopwatch started inside the helper **before**
///   the `expect(kCtE2EEnabled, isTrue, ...)` gate so the eventual
///   `test_total` slice covers the same span the pre-lift inline blocks
///   covered. Standard / fleet callers continue to either back the
///   wall-clock guard with this stopwatch (standard) or with a fresh
///   stopwatch started later (fleet), matching their pre-lift behaviour.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
class E2eIntegrationTestBootstrapResult {
  const E2eIntegrationTestBootstrapResult({
    required this.perf,
    required this.testSw,
  });

  /// Scenario-scoped perf log; downstream phases continue to forward it
  /// into shared helpers so the `E2E_TIMING|test=<testName>|...`
  /// attribution remains stable.
  final E2ePerfLog perf;

  /// Wall-clock stopwatch started inside the helper at the
  /// `expect(kCtE2EEnabled, isTrue, ...)` gate. Call sites stop measuring
  /// against it at `perf.timing('test_total', testSw.elapsed, ...)` time.
  final Stopwatch testSw;
}

/// Drives the canonical `IntegrationTestWidgetsFlutterBinding`-side
/// bootstrap shared by every standard / fleet E2E preamble:
///
/// 1. scenario-scoped [E2ePerfLog] + outer `testSw` stopwatch (started
///    **before** the `expect` gate),
/// 2. `expect(kCtE2EEnabled, isTrue, ...)` gate,
/// 3. `tester.binding.setSurfaceSize(surfaceSize)`,
/// 4. `await bootstrapForIntegrationTest()` + first `tester.pump()` +
///    [e2eWaitForNewGameEntry],
/// 5. `perf.timing(bootstrapTimingPhase, bootstrapSw.elapsed)`.
///
/// Both [e2eEnterStandardE2eScenario]
/// (`e2e_test_shared_standard_scenario_opener.dart`) and
/// [e2eEnterFleetReachScenarioReady]
/// (`e2e_test_shared_fleet_reach_scenario_preamble.dart`) inlined this
/// exact ~10-line block verbatim before the lift. The two preambles
/// diverge **after** these steps — standard times an `asset_preload`
/// slice next, fleet starts a fresh wall-clock stopwatch instead — so
/// the lift covers only the common bootstrap-to-`New Game`-entry window,
/// not the asset-preload, new-game-to-map, or wall-clock-guard
/// construction. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
///
/// Why `bootstrapForIntegrationTest` is an injected parameter: the only
/// real call sites forward `bootstrapForIntegrationTest` from
/// `package:colonizethis_app/main.dart`, but pulling that symbol into the
/// shared E2E module would couple every consumer of `e2e_test_shared.dart`
/// to the app's main entry-point — including the widget-test pins under
/// `app/test/`, which mount minimal `MaterialApp` fixtures rather than
/// the full app. Injecting the bootstrap callable keeps the shared module
/// free of the main-entry import and lets the pin file exercise the
/// callable-parameter contract without booting the real game.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). The widget-test pin in
/// `app/test/e2e_run_integration_test_bootstrap_test.dart` carries the
/// behavioural contract: constants, value-class shape, and AC1 barrel
/// forwarding signature.
///
/// Contract:
///
/// - Creates [E2eIntegrationTestBootstrapResult.perf] as
///   `E2ePerfLog(testName)` and starts [E2eIntegrationTestBootstrapResult.testSw]
///   **before** the `expect(kCtE2EEnabled, isTrue, ...)` gate so the
///   eventual `test_total` slice covers the same span the pre-lift
///   inline blocks did.
/// - Fails with the canonical
///   `Run with: flutter test integration_test/... --dart-define=CT_E2E=true`
///   reason when [kCtE2EEnabled] is `false`, matching the pre-lift
///   inline `expect` reasons in both preambles byte-for-byte.
/// - Calls `tester.binding.setSurfaceSize(surfaceSize)` (default
///   [kE2eDefaultIntegrationTestBootstrapSurfaceSize] = `Size(1280, 720)`)
///   before the bootstrap callable so Flame viewport sizing matches the
///   pre-lift inline behaviour.
/// - Awaits the injected [bootstrapForIntegrationTest], then issues one
///   `tester.pump()` so the engine settles whatever microtasks the
///   bootstrap scheduled. The same single-frame pump appeared verbatim
///   in both pre-lift inline blocks; the `e2eWaitForNewGameEntry` call
///   immediately following does its own adaptive polling so the pump is
///   the canonical Flutter `tap → pump → await` ordering rather than a
///   wasted settle.
/// - Calls [e2eWaitForNewGameEntry] with the scenario perf log so the
///   shared adaptive-poll path attributes its slices to the same test
///   identifier the rest of the scenario uses.
/// - Emits exactly one `E2E_TIMING|...|phase=$bootstrapTimingPhase`
///   slice (default phase
///   [kE2eDefaultIntegrationTestBootstrapTimingPhase] =
///   `bootstrap_for_integration_test`) covering the
///   bootstrap-through-`New Game`-entry window. Call sites that need a
///   different phase label pass `bootstrapTimingPhase: '<name>'`.
/// - Returns an [E2eIntegrationTestBootstrapResult] carrying the perf
///   log and the test wall-clock stopwatch. The helper does **not**
///   build a wall-clock guard — standard scenarios back the guard with
///   the returned `testSw`, fleet scenarios start a fresh stopwatch
///   later, and surfacing both branches behind a shared helper would
///   either lose that distinction or force a confusing
///   `useFreshWallClockStopwatch` flag at every call site.
Future<E2eIntegrationTestBootstrapResult> e2eRunIntegrationTestBootstrap(
  WidgetTester tester, {
  required String testName,
  required Future<void> Function() bootstrapForIntegrationTest,
  Size surfaceSize = kE2eDefaultIntegrationTestBootstrapSurfaceSize,
  String bootstrapTimingPhase = kE2eDefaultIntegrationTestBootstrapTimingPhase,
}) async {
  final perf = E2ePerfLog(testName);
  final testSw = Stopwatch()..start();
  expect(
    kCtE2EEnabled,
    isTrue,
    reason:
        'Run with: flutter test integration_test/... --dart-define=CT_E2E=true',
  );

  await tester.binding.setSurfaceSize(surfaceSize);

  final bootstrapSw = Stopwatch()..start();
  await bootstrapForIntegrationTest();
  await tester.pump();
  await e2eWaitForNewGameEntry(tester, perf: perf);
  perf.timing(bootstrapTimingPhase, bootstrapSw.elapsed);

  return E2eIntegrationTestBootstrapResult(perf: perf, testSw: testSw);
}
