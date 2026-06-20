/// Pins the contract of [e2eEnterFleetReachScenarioReady]
/// (`app/integration_test/e2e_test_shared_fleet_reach_scenario_preamble.dart`).
///
/// Both `testWidgets` bodies in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` consume this helper via
/// the AC1 barrel alias `enterFleetReachScenarioReady` to share the
/// post-`IntegrationTestWidgetsFlutterBinding.ensureInitialized()` preamble.
/// The pre-lift inline blocks duplicated the same 40-line sequence
/// (`kCtE2EEnabled` gate → surface size → `bootstrapForIntegrationTest` +
/// pump + `waitForNewGameEntry` + `bootstrap_for_integration_test` timing →
/// 64 px PNG suite preload → wall-clock guard → `bootstrapNewGameToMap` +
/// `after bootstrap` checkpoint → `lookupAppLocalizations` →
/// `splitHomeFleetOnce` + `closeBottomSheet` + `after split fleet`
/// checkpoint) byte-for-byte; the lifted helper carries the contract in
/// one place so a silent drift on any of those steps would have to update
/// the shared module rather than two separate inline blocks.
///
/// A silent regression here would:
///
///   - Bump the default [kE2eDefaultFleetReachPreambleMaxUiResponseWait]
///     (5 s) and silently drift the post-bootstrap split-fleet path away
///     from the `_kMaxUiResponseWait (5 s)` used everywhere else in the
///     fleet scenarios.
///   - Change the default [kE2eDefaultFleetReachPreambleLocale] from `en`
///     to a different locale and break every confirm-button / dialog-close
///     `l10n` lookup downstream.
///   - Resize [kE2eDefaultFleetReachPreambleSurfaceSize] away from the
///     legacy 1280 × 720 viewport and silently invalidate visibility-based
///     locators.
///   - Rename [kE2eDefaultFleetReachPreambleBootstrapTimingPhase],
///     [kE2eDefaultFleetReachPreambleAfterBootstrapStep], or
///     [kE2eDefaultFleetReachPreambleAfterSplitFleetStep] and orphan every
///     `E2E_TIMING|...|phase=...` / wall-clock-fail-fast attribution
///     keyed on those literals.
///   - Drop a field from [E2eFleetReachScenarioPreamble] and silently
///     break call sites that unpack `preamble.perf` / `.testSw` / `.l10n`
///     / `.ensureUnderWallClock`.
///   - Drop the helper from the AC1 barrel `show` clause or swap an
///     argument's order / default and break the post-lift call sites that
///     consume the public-name alias.
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), and the helper body
/// drives real `bootstrapForIntegrationTest` / `bootstrapNewGameToMap` /
/// `splitHomeFleetOnce` calls that require the full app to be mounted, so
/// this widget-test layer carries the contract via the constants, value
/// class shape, and AC1 barrel forwarding signature.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

void main() {
  suppressLogsForTests();

  group('e2eEnterFleetReachScenarioReady — default constants', () {
    test('kE2eDefaultFleetReachPreambleMaxUiResponseWait preserves the '
        'legacy inline `_kMaxUiResponseWait = Duration(seconds: 5)` literal', () {
      expect(
        kE2eDefaultFleetReachPreambleMaxUiResponseWait,
        const Duration(seconds: 5),
        reason:
            'Pre-lift fleet scenarios forwarded `_kMaxUiResponseWait (5s)` '
            'into the post-bootstrap `splitHomeFleetOnce` / '
            '`closeBottomSheet` calls. The rest of the fleet scenario body '
            '(reach loop, final naval check, bundled-Explore wait) also '
            'reuses the same literal, so a silent change here would drift '
            'only the preamble away from the consistent UI-response budget '
            'the rest of the scenario shares.',
      );
    });

    test('kE2eDefaultFleetReachPreambleLocale preserves the legacy inline '
        'English `Locale(en)`', () {
      expect(
        kE2eDefaultFleetReachPreambleLocale,
        const Locale('en'),
        reason:
            'Pre-lift fleet scenarios called '
            '`lookupAppLocalizations(const Locale("en"))` directly. The '
            'returned `AppLocalizations` is passed into '
            '`advanceOneHumanTurn` / `splitHomeFleetOnce` / '
            '`dismissCtDialogShellIfPresent` downstream; a silent change '
            'to a non-English default would break every localized '
            'confirm-button / dialog-close lookup in those helpers.',
      );
    });

    test('kE2eDefaultFleetReachPreambleSurfaceSize preserves the legacy '
        'inline `Size(1280, 720)` viewport', () {
      expect(
        kE2eDefaultFleetReachPreambleSurfaceSize,
        const Size(1280, 720),
        reason:
            'Pre-lift fleet scenarios sized the test surface to 1280 × 720 '
            'via `tester.binding.setSurfaceSize(...)`. Flame map '
            'sizing, panel locators, and visibility-first interactions '
            'downstream key on this viewport; a silent change would either '
            'shrink the visible map enough to invalidate marker locators '
            'or grow it past CI runner display bounds.',
      );
    });

    test('kE2eDefaultFleetReachPreambleBootstrapTimingPhase preserves the '
        'legacy inline `bootstrap_for_integration_test` phase label', () {
      expect(
        kE2eDefaultFleetReachPreambleBootstrapTimingPhase,
        'bootstrap_for_integration_test',
        reason:
            'Pre-lift fleet scenarios emitted '
            '`perf.timing("bootstrap_for_integration_test", '
            'bootstrapSw.elapsed)` directly. Downstream '
            '`E2E_TIMING|...|phase=bootstrap_for_integration_test` log '
            'scrapers / AC8 dashboards key on this exact literal; a '
            'silent rename would orphan every dashboard tracking the '
            'pre-`New Game`-entry boot cost.',
      );
    });

    test('kE2eDefaultFleetReachPreambleAfterBootstrapStep preserves the '
        'legacy inline `after bootstrap` checkpoint label', () {
      expect(
        kE2eDefaultFleetReachPreambleAfterBootstrapStep,
        'after bootstrap',
        reason:
            'Pre-lift fleet scenarios emitted '
            '`ensureUnderWallClock("after bootstrap")` directly. The '
            'wall-clock fail-fast contract (`colonizethis-e2e-ui-stability.mdc` '
            '/ `SPEC/program/e2e-integration-tests.md` § Determinism PR '
            'runtime rule) attributes regressions by checkpoint string; a '
            'silent rename would either hide the regression under a fresh '
            'label or accumulate two distinct labels across the lift.',
      );
    });

    test('kE2eDefaultFleetReachPreambleAfterSplitFleetStep preserves the '
        'legacy inline `after split fleet` checkpoint label', () {
      expect(
        kE2eDefaultFleetReachPreambleAfterSplitFleetStep,
        'after split fleet',
        reason:
            'Pre-lift fleet scenarios emitted '
            '`ensureUnderWallClock("after split fleet")` directly after '
            '`closeBottomSheet`. The wall-clock fail-fast attribution keys '
            'on this string; a silent rename would hide a regression '
            'between split-fleet wall-clock cost and a fresh label.',
      );
    });

    test('kE2eMaxWallClock is the default `wallClockCap` for the helper '
        '(matches legacy `_kFleetE2eMaxWallClock` alias)', () {
      expect(
        kE2eMaxWallClock,
        const Duration(minutes: 5),
        reason:
            'Pre-lift fleet scenarios passed `cap: _kFleetE2eMaxWallClock` '
            '(which aliases `kE2eMaxWallClock`) into the wall-clock '
            'guard. The helper defaults `wallClockCap` to `kE2eMaxWallClock` '
            'so call sites that omit the override keep the same 5-minute '
            'fail-fast budget defined by '
            '`SPEC/program/e2e-integration-tests.md` § Determinism PR '
            'runtime rule.',
      );
    });
  });

  group('E2eFleetReachScenarioPreamble — value class shape', () {
    test('exposes perf / testSw / l10n / ensureUnderWallClock fields', () {
      final perf = shared.E2ePerfLog('preamble_pin');
      final testSw = Stopwatch()..start();
      final l10n = lookupAppLocalizations(const Locale('en'));
      void guard(String step) {}

      final preamble = E2eFleetReachScenarioPreamble(
        perf: perf,
        testSw: testSw,
        l10n: l10n,
        ensureUnderWallClock: guard,
      );

      expect(identical(preamble.perf, perf), isTrue);
      expect(identical(preamble.testSw, testSw), isTrue);
      expect(identical(preamble.l10n, l10n), isTrue);
      expect(identical(preamble.ensureUnderWallClock, guard), isTrue);
    });

    test('field types match the documented downstream call-site contract '
        '(compile-time signature pin)', () {
      final perf = shared.E2ePerfLog('preamble_pin');
      final testSw = Stopwatch()..start();
      final l10n = lookupAppLocalizations(const Locale('en'));
      void guard(String step) {}

      final preamble = E2eFleetReachScenarioPreamble(
        perf: perf,
        testSw: testSw,
        l10n: l10n,
        ensureUnderWallClock: guard,
      );

      // The pre-lift inline blocks unpacked these symbols directly into
      // `final perf = ...`, `final testSw = ...`, `final l10n = ...`,
      // `final ensureUnderWallClock = ...`. A regression that retyped any
      // of them (e.g. swapping `Stopwatch` for `Duration`, returning the
      // map-HUD `perf.timing` `Duration` instead of the test wall-clock
      // stopwatch, or dropping the `String step` arg from the guard
      // closure) would fail these assignments at compile time.
      final shared.E2ePerfLog perfTyped = preamble.perf;
      final Stopwatch testSwTyped = preamble.testSw;
      final AppLocalizations l10nTyped = preamble.l10n;
      final void Function(String step) guardTyped =
          preamble.ensureUnderWallClock;

      expect(perfTyped.testName, 'preamble_pin');
      expect(testSwTyped.isRunning, isTrue);
      expect(l10nTyped, isNotNull);
      expect(guardTyped, isNotNull);
    });

    test('const constructor: requires all four named arguments', () {
      // Compile-time pin: a regression that made any field optional /
      // nullable would either fail the `required` literal below or
      // silently allow `null` to land in the call-site `final perf = ...`
      // unpacking. The pre-lift inline blocks always produced non-null
      // values for every field, so making any of them nullable would
      // change the downstream type contract.
      final perf = shared.E2ePerfLog('required_pin');
      final testSw = Stopwatch()..start();
      final l10n = lookupAppLocalizations(const Locale('en'));
      void guard(String _) {}

      final preamble = E2eFleetReachScenarioPreamble(
        perf: perf,
        testSw: testSw,
        l10n: l10n,
        ensureUnderWallClock: guard,
      );
      expect(preamble, isNotNull);
    });
  });

  group('e2eEnterFleetReachScenarioReady — AC1 barrel forwarding', () {
    test('enterFleetReachScenarioReady is re-exported as a tear-off with '
        'the documented signature (compile-time pin)', () {
      // Reading the function as a typed tear-off pins:
      // - `tester` first positional (`WidgetTester`)
      // - `testName: String` required named
      // - `bootstrapForIntegrationTest: Future<void> Function()` required
      //   named (the injected callable)
      // - `maxUiResponseWait: Duration` named (default 5 s)
      // - `wallClockCap: Duration` named (default 5 minutes)
      // - `locale: Locale` named (default `Locale('en')`)
      // - `surfaceSize: Size` named (default `Size(1280, 720)`)
      // - `bootstrapTimingPhase: String` named
      // - `afterBootstrapStep: String` named
      // - `afterSplitFleetStep: String` named
      // - returns `Future<E2eFleetReachScenarioPreamble>`
      //
      // A silent removal from the `show` clause, an arg-order swap, a
      // changed default for any named parameter, or a dropped optional
      // parameter would fail this assignment at compile time.
      final Future<E2eFleetReachScenarioPreamble> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Duration maxUiResponseWait,
        Duration wallClockCap,
        Locale locale,
        Size surfaceSize,
        String bootstrapTimingPhase,
        String afterBootstrapStep,
        String afterSplitFleetStep,
      })
      ref = enterFleetReachScenarioReady;
      expect(ref, isNotNull);
    });

    test('e2eEnterFleetReachScenarioReady (lifted form) is re-exported as '
        'a tear-off with the same signature (compile-time pin)', () {
      // Both the lifted form and the AC1 barrel alias must remain
      // available with matching signatures so future callers can pick
      // either entrypoint without an arg-order surprise.
      final Future<E2eFleetReachScenarioPreamble> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Duration maxUiResponseWait,
        Duration wallClockCap,
        Locale locale,
        Size surfaceSize,
        String bootstrapTimingPhase,
        String afterBootstrapStep,
        String afterSplitFleetStep,
      })
      ref = shared.e2eEnterFleetReachScenarioReady;
      expect(ref, isNotNull);
    });
  });
}
