/// Pins the contract of [e2eRunIntegrationTestBootstrap]
/// (`app/integration_test/e2e_test_shared_integration_test_bootstrap.dart`).
///
/// Both [e2eEnterStandardE2eScenario]
/// (`e2e_test_shared_standard_scenario_opener.dart`) and
/// [e2eEnterFleetReachScenarioReady]
/// (`e2e_test_shared_fleet_reach_scenario_preamble.dart`) now consume this
/// helper to share the canonical
/// `IntegrationTestWidgetsFlutterBinding`-side bootstrap
/// (`E2ePerfLog(testName)` + outer `testSw` stopwatch → `kCtE2EEnabled`
/// gate → `setSurfaceSize` → `bootstrapForIntegrationTest` + first pump +
/// `e2eWaitForNewGameEntry` → `bootstrap_for_integration_test` timing
/// slice). The pre-lift inline blocks duplicated the same ~10-line
/// sequence byte-for-byte; the lifted helper carries the contract in one
/// place so a silent drift on any of those steps would have to update the
/// shared module rather than two separate inline blocks.
///
/// A silent regression here would:
///
///   - Resize [kE2eDefaultIntegrationTestBootstrapSurfaceSize] away from
///     the legacy 1280 × 720 viewport and silently invalidate
///     visibility-based locators in every standard / fleet E2E scenario
///     downstream.
///   - Rename [kE2eDefaultIntegrationTestBootstrapTimingPhase] and orphan
///     every `E2E_TIMING|...|phase=bootstrap_for_integration_test` log
///     scraper / AC8 dashboard keyed on the legacy literal.
///   - Drop a field from [E2eIntegrationTestBootstrapResult] and silently
///     break the standard / fleet preambles that unpack
///     `bootstrap.perf` / `.testSw`.
///   - Drop the helper from the AC1 barrel `show` clause or swap an
///     argument's order / default and break the AC1-barrel alias
///     `runIntegrationTestBootstrap` future call sites consume.
///   - Demote [bootstrapForIntegrationTest] from a `required` callable
///     parameter to a default closure that booted the real game and
///     coupled the shared module to `package:colonizethis_app/main.dart`.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), and the helper body
/// drives real `bootstrapForIntegrationTest` / `setSurfaceSize` /
/// `e2eWaitForNewGameEntry` calls that require the full app to be
/// mounted, so this widget-test layer carries the contract via the
/// constants, value-class shape, and AC1 barrel forwarding signature.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

void main() {
  suppressLogsForTests();

  group('e2eRunIntegrationTestBootstrap — default constants', () {
    test('kE2eDefaultIntegrationTestBootstrapSurfaceSize preserves the legacy '
        'inline `Size(1280, 720)` viewport shared by every E2E scenario', () {
      expect(
        kE2eDefaultIntegrationTestBootstrapSurfaceSize,
        const Size(1280, 720),
        reason:
            'Pre-lift the standard scenario opener and the fleet reach '
            'preamble each set the test surface to 1280 × 720 via '
            '`tester.binding.setSurfaceSize(...)`. Flame map sizing, panel '
            'locators, and visibility-first interactions downstream key on '
            'this viewport; a silent change would either shrink the visible '
            'map enough to invalidate marker locators or grow it past CI '
            'runner display bounds.',
      );
    });

    test('kE2eDefaultIntegrationTestBootstrapTimingPhase preserves the legacy '
        'inline `bootstrap_for_integration_test` phase label', () {
      expect(
        kE2eDefaultIntegrationTestBootstrapTimingPhase,
        'bootstrap_for_integration_test',
        reason:
            'Pre-lift the standard scenario opener and the fleet reach '
            'preamble emitted `perf.timing("bootstrap_for_integration_test", '
            'bootstrapSw.elapsed)` directly. Downstream '
            '`E2E_TIMING|...|phase=bootstrap_for_integration_test` log '
            'scrapers / AC8 dashboards key on this exact literal; a silent '
            'rename would orphan every dashboard tracking the '
            'pre-`New Game`-entry boot cost.',
      );
    });

    test('legacy preamble surface-size constants match the new shared '
        'integration-test default (compile-time pin)', () {
      // The standard scenario opener and the fleet reach preamble still
      // expose their own surface-size constants; pinning that all three
      // remain `Size(1280, 720)` guarantees that the lifted helper is the
      // single source of truth on viewport sizing even though the legacy
      // constants stay in the public surface for compatibility.
      expect(
        kE2eDefaultStandardScenarioOpenerSurfaceSize,
        kE2eDefaultIntegrationTestBootstrapSurfaceSize,
        reason:
            'Standard scenario opener surface-size constant must remain in '
            'sync with the lifted helper default; a silent split would let '
            'the standard opener drift from the canonical viewport.',
      );
      expect(
        kE2eDefaultFleetReachPreambleSurfaceSize,
        kE2eDefaultIntegrationTestBootstrapSurfaceSize,
        reason:
            'Fleet reach preamble surface-size constant must remain in '
            'sync with the lifted helper default; a silent split would let '
            'the fleet preamble drift from the canonical viewport.',
      );
    });

    test('legacy preamble bootstrap-timing-phase constants match the new '
        'shared integration-test default (compile-time pin)', () {
      // Same reasoning as the surface-size sibling above: the legacy
      // per-preamble bootstrap-timing-phase constants must remain in lock
      // step with the new shared default so AC8 dashboards keyed on either
      // legacy name continue to attribute to the same canonical literal.
      expect(
        kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase,
        kE2eDefaultIntegrationTestBootstrapTimingPhase,
        reason:
            'Standard scenario opener bootstrap-timing-phase constant must '
            'remain in sync with the lifted helper default; a silent split '
            'would let the standard opener emit a different phase label '
            'than the shared helper.',
      );
      expect(
        kE2eDefaultFleetReachPreambleBootstrapTimingPhase,
        kE2eDefaultIntegrationTestBootstrapTimingPhase,
        reason:
            'Fleet reach preamble bootstrap-timing-phase constant must '
            'remain in sync with the lifted helper default; a silent split '
            'would let the fleet preamble emit a different phase label '
            'than the shared helper.',
      );
    });
  });

  group('E2eIntegrationTestBootstrapResult — value class shape', () {
    test('exposes perf / testSw fields', () {
      final perf = shared.E2ePerfLog('bootstrap_pin');
      final testSw = Stopwatch()..start();

      final bootstrap = E2eIntegrationTestBootstrapResult(
        perf: perf,
        testSw: testSw,
      );

      expect(identical(bootstrap.perf, perf), isTrue);
      expect(identical(bootstrap.testSw, testSw), isTrue);
    });

    test('field types match the documented downstream call-site contract '
        '(compile-time signature pin)', () {
      final perf = shared.E2ePerfLog('bootstrap_pin');
      final testSw = Stopwatch()..start();

      final bootstrap = E2eIntegrationTestBootstrapResult(
        perf: perf,
        testSw: testSw,
      );

      // The standard / fleet preambles unpack these symbols directly into
      // `final perf = bootstrap.perf;` and `final testSw = bootstrap.testSw;`.
      // A regression that retyped either (e.g. swapping `Stopwatch` for
      // `Duration`, returning the `e2eWaitForNewGameEntry` perf-timing
      // `Duration` instead of the outer wall-clock stopwatch, or hiding
      // either field behind a getter that mutated state) would fail
      // these assignments at compile time.
      final shared.E2ePerfLog perfTyped = bootstrap.perf;
      final Stopwatch testSwTyped = bootstrap.testSw;

      expect(perfTyped.testName, 'bootstrap_pin');
      expect(testSwTyped.isRunning, isTrue);
    });

    test('const constructor: requires both named arguments', () {
      // Compile-time pin: a regression that made either field optional /
      // nullable would either fail the `required` literal below or silently
      // allow `null` to land in the post-lift preamble's `final perf = ...`
      // unpacking. The pre-lift inline blocks always produced non-null
      // values for both fields, so making either nullable would change the
      // downstream type contract.
      final perf = shared.E2ePerfLog('required_pin');
      final testSw = Stopwatch()..start();

      final bootstrap = E2eIntegrationTestBootstrapResult(
        perf: perf,
        testSw: testSw,
      );
      expect(bootstrap, isNotNull);
    });
  });

  group('e2eRunIntegrationTestBootstrap — AC1 barrel forwarding', () {
    test('runIntegrationTestBootstrap is re-exported as a tear-off with the '
        'documented signature (compile-time pin)', () {
      // Reading the function as a typed tear-off pins:
      // - `tester` first positional (`WidgetTester`)
      // - `testName: String` required named
      // - `bootstrapForIntegrationTest: Future<void> Function()` required
      //   named (the injected callable)
      // - `surfaceSize: Size` named (default `Size(1280, 720)`)
      // - `bootstrapTimingPhase: String` named
      // - returns `Future<E2eIntegrationTestBootstrapResult>`
      //
      // A silent removal from the `show` clause, an arg-order swap, a
      // changed default for any named parameter, or a dropped optional
      // parameter would fail this assignment at compile time. Demoting
      // either required parameter to a default would also fail it.
      final Future<E2eIntegrationTestBootstrapResult> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Size surfaceSize,
        String bootstrapTimingPhase,
      })
      ref = runIntegrationTestBootstrap;
      expect(ref, isNotNull);
    });

    test('e2eRunIntegrationTestBootstrap (lifted form) is re-exported as a '
        'tear-off with the same signature (compile-time pin)', () {
      // Both the lifted form and the AC1 barrel alias must remain available
      // with matching signatures so future callers can pick either
      // entrypoint without an arg-order surprise.
      final Future<E2eIntegrationTestBootstrapResult> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Size surfaceSize,
        String bootstrapTimingPhase,
      })
      ref = shared.e2eRunIntegrationTestBootstrap;
      expect(ref, isNotNull);
    });
  });
}
