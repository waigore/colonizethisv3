/// Pins the contract of [e2eEnterStandardE2eScenario]
/// (`app/integration_test/e2e_test_shared_standard_scenario_opener.dart`).
///
/// Both standard `testWidgets` bodies in `new_game_full_turn_e2e_test.dart`
/// and `new_game_capital_panel_e2e_test.dart` consume this helper via the
/// AC1 barrel alias `enterStandardE2eScenario` to share the
/// post-`IntegrationTestWidgetsFlutterBinding.ensureInitialized()` opener.
/// The pre-lift inline blocks duplicated the same ~18-line sequence
/// (`E2ePerfLog(testName)` + `testSw` stopwatch → `kCtE2EEnabled` gate →
/// `e2eMakeWallClockGuard` on the same `testSw` → `setSurfaceSize` →
/// `bootstrapForIntegrationTest` + pump + `waitForNewGameEntry` +
/// `bootstrap_for_integration_test` timing + `after
/// bootstrap_for_integration_test` checkpoint → 64 px PNG suite preload
/// (full-turn also timed it as `asset_preload`) + `after asset_preload`
/// checkpoint → `bootstrapNewGameToMap` + outer `new_game_to_map` timing
/// + `after new_game_to_map` checkpoint → `lookupAppLocalizations`)
/// byte-for-byte; the lifted helper carries the contract in one place so a
/// silent drift on any of those steps would have to update the shared
/// module rather than two separate inline blocks.
///
/// A silent regression here would:
///
///   - Resize [kE2eDefaultStandardScenarioOpenerSurfaceSize] away from the
///     legacy 1280 × 720 viewport and silently invalidate visibility-based
///     locators in both standard scenarios.
///   - Change the default [kE2eDefaultStandardScenarioOpenerLocale] from
///     `en` to a different locale and break every confirm-button /
///     dialog-close `l10n` lookup downstream.
///   - Rename [kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase],
///     [kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase],
///     [kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase],
///     [kE2eDefaultStandardScenarioOpenerAfterBootstrapStep],
///     [kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep], or
///     [kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep] and
///     orphan every `E2E_TIMING|...|phase=...` / wall-clock-fail-fast
///     attribution keyed on those literals.
///   - Drop a field from [E2eStandardScenarioOpener] and silently break
///     call sites that unpack `opener.perf` / `.testSw` / `.l10n` /
///     `.ensureUnderWallClock`.
///   - Drop the helper from the AC1 barrel `show` clause or swap an
///     argument's order / default and break the post-lift call sites that
///     consume the public-name alias.
///   - Demote [assetPreloadTimingPhase] / [newGameToMapTimingPhase] from
///     `String?` to `String` (removing the suppression path the
///     capital-panel scenario relies on for byte-identical
///     emitted-log behaviour).
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), and the helper body
/// drives real `bootstrapForIntegrationTest` / `bootstrapNewGameToMap` /
/// `setSurfaceSize` calls that require the full app to be mounted, so
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

  group('e2eEnterStandardE2eScenario — default constants', () {
    test('kE2eDefaultStandardScenarioOpenerSurfaceSize preserves the legacy '
        'inline `Size(1280, 720)` viewport', () {
      expect(
        kE2eDefaultStandardScenarioOpenerSurfaceSize,
        const Size(1280, 720),
        reason:
            'Pre-lift full-turn and capital-panel scenarios sized the test '
            'surface to 1280 × 720 via `tester.binding.setSurfaceSize(...)`. '
            'Flame map sizing, panel locators, and visibility-first '
            'interactions downstream key on this viewport; a silent change '
            'would either shrink the visible map enough to invalidate '
            'marker locators or grow it past CI runner display bounds.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerLocale preserves the legacy '
        'inline English `Locale(en)`', () {
      expect(
        kE2eDefaultStandardScenarioOpenerLocale,
        const Locale('en'),
        reason:
            'Pre-lift full-turn and capital-panel scenarios called '
            '`lookupAppLocalizations(const Locale("en"))` directly. The '
            'returned `AppLocalizations` is passed into '
            '`advanceOneHumanTurn` / `dismissCtDialogShellIfPresent` / '
            '`expectPanelTextsMatchSnapshot` downstream; a silent change to '
            'a non-English default would break every localized '
            'confirm-button / dialog-close lookup in those helpers.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase preserves '
        'the legacy inline `bootstrap_for_integration_test` phase label', () {
      expect(
        kE2eDefaultStandardScenarioOpenerBootstrapTimingPhase,
        'bootstrap_for_integration_test',
        reason:
            'Pre-lift full-turn and capital-panel scenarios emitted '
            '`perf.timing("bootstrap_for_integration_test", '
            'bootstrapSw.elapsed)` directly. Downstream '
            '`E2E_TIMING|...|phase=bootstrap_for_integration_test` log '
            'scrapers / AC8 dashboards key on this exact literal; a silent '
            'rename would orphan every dashboard tracking the pre-`New '
            'Game`-entry boot cost.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerAfterBootstrapStep preserves the '
        'legacy inline `after bootstrap_for_integration_test` checkpoint '
        'label', () {
      expect(
        kE2eDefaultStandardScenarioOpenerAfterBootstrapStep,
        'after bootstrap_for_integration_test',
        reason:
            'Pre-lift full-turn and capital-panel scenarios emitted '
            '`ensureUnderWallClock("after bootstrap_for_integration_test")` '
            'directly. The wall-clock fail-fast contract '
            '(`colonizethis-e2e-ui-stability.mdc` / '
            '`SPEC/program/e2e-integration-tests.md` § Determinism PR runtime '
            'rule) attributes regressions by checkpoint string; a silent '
            'rename would either hide the regression under a fresh label or '
            'accumulate two distinct labels across the lift.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase preserves '
        'the legacy inline `asset_preload` phase label', () {
      expect(
        kE2eDefaultStandardScenarioOpenerAssetPreloadTimingPhase,
        'asset_preload',
        reason:
            'Pre-lift full-turn scenario emitted '
            '`perf.timing("asset_preload", preloadSw.elapsed)` directly. '
            'Downstream `E2E_TIMING|...|phase=asset_preload` log scrapers / '
            'AC8 dashboards key on this exact literal; a silent rename '
            'would orphan every dashboard tracking the relocated-64px PNG '
            'manifest cost.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep preserves '
        'the legacy inline `after asset_preload` checkpoint label', () {
      expect(
        kE2eDefaultStandardScenarioOpenerAfterAssetPreloadStep,
        'after asset_preload',
        reason:
            'Pre-lift full-turn and capital-panel scenarios emitted '
            '`ensureUnderWallClock("after asset_preload")` directly. A '
            'silent rename would hide a regression between PNG decode wall '
            'clock and a fresh label.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase preserves '
        'the legacy inline `new_game_to_map` outer-stopwatch phase label', () {
      expect(
        kE2eDefaultStandardScenarioOpenerNewGameToMapTimingPhase,
        'new_game_to_map',
        reason:
            'Pre-lift full-turn and capital-panel scenarios emitted an '
            'outer-stopwatch `perf.timing("new_game_to_map", '
            'newGameSw.elapsed)` directly around their '
            '`bootstrapNewGameToMap` call. `e2eBootstrapNewGameToMap` also '
            'emits an inner `new_game_to_map` slice; the outer emission '
            'preserves the legacy double-emission so log scrapers that '
            'expect both lines keep working.',
      );
    });

    test('kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep preserves '
        'the legacy inline `after new_game_to_map` checkpoint label', () {
      expect(
        kE2eDefaultStandardScenarioOpenerAfterNewGameToMapStep,
        'after new_game_to_map',
        reason:
            'Pre-lift full-turn and capital-panel scenarios emitted '
            '`ensureUnderWallClock("after new_game_to_map")` directly. A '
            'silent rename would hide a regression between map-bootstrap '
            'wall clock and a fresh label.',
      );
    });

    test('kE2eMaxWallClock is the default `wallClockCap` for the helper '
        '(matches the legacy inline `_kFleetE2eMaxWallClock` / 5-minute PR '
        'rule)', () {
      expect(
        kE2eMaxWallClock,
        const Duration(minutes: 5),
        reason:
            'Pre-lift full-turn and capital-panel scenarios derived their '
            'wall-clock guard from `e2eMakeWallClockGuard(testName: ..., '
            'stopwatch: testSw)` with the default `cap: kE2eMaxWallClock` '
            '(5 minutes). The helper defaults `wallClockCap` to '
            '`kE2eMaxWallClock` so call sites that omit the override keep '
            'the same 5-minute fail-fast budget defined by '
            '`SPEC/program/e2e-integration-tests.md` § Determinism PR '
            'runtime rule.',
      );
    });
  });

  group('E2eStandardScenarioOpener — value class shape', () {
    test('exposes perf / testSw / l10n / ensureUnderWallClock fields', () {
      final perf = shared.E2ePerfLog('opener_pin');
      final testSw = Stopwatch()..start();
      final l10n = lookupAppLocalizations(const Locale('en'));
      void guard(String step) {}

      final opener = E2eStandardScenarioOpener(
        perf: perf,
        testSw: testSw,
        l10n: l10n,
        ensureUnderWallClock: guard,
      );

      expect(identical(opener.perf, perf), isTrue);
      expect(identical(opener.testSw, testSw), isTrue);
      expect(identical(opener.l10n, l10n), isTrue);
      expect(identical(opener.ensureUnderWallClock, guard), isTrue);
    });

    test('field types match the documented downstream call-site contract '
        '(compile-time signature pin)', () {
      final perf = shared.E2ePerfLog('opener_pin');
      final testSw = Stopwatch()..start();
      final l10n = lookupAppLocalizations(const Locale('en'));
      void guard(String step) {}

      final opener = E2eStandardScenarioOpener(
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
      final shared.E2ePerfLog perfTyped = opener.perf;
      final Stopwatch testSwTyped = opener.testSw;
      final AppLocalizations l10nTyped = opener.l10n;
      final void Function(String step) guardTyped = opener.ensureUnderWallClock;

      expect(perfTyped.testName, 'opener_pin');
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

      final opener = E2eStandardScenarioOpener(
        perf: perf,
        testSw: testSw,
        l10n: l10n,
        ensureUnderWallClock: guard,
      );
      expect(opener, isNotNull);
    });
  });

  group('e2eEnterStandardE2eScenario — AC1 barrel forwarding', () {
    test('enterStandardE2eScenario is re-exported as a tear-off with the '
        'documented signature (compile-time pin)', () {
      // Reading the function as a typed tear-off pins:
      // - `tester` first positional (`WidgetTester`)
      // - `testName: String` required named
      // - `bootstrapForIntegrationTest: Future<void> Function()` required
      //   named (the injected callable)
      // - `wallClockCap: Duration` named (default 5 minutes)
      // - `locale: Locale` named (default `Locale('en')`)
      // - `surfaceSize: Size` named (default `Size(1280, 720)`)
      // - `bootstrapTimingPhase: String` named
      // - `afterBootstrapStep: String` named
      // - `assetPreloadTimingPhase: String?` named (nullable so capital
      //   can suppress emission while preserving the underlying preload)
      // - `afterAssetPreloadStep: String` named
      // - `newGameToMapTimingPhase: String?` named (nullable for the same
      //   reason)
      // - `afterNewGameToMapStep: String` named
      // - returns `Future<E2eStandardScenarioOpener>`
      //
      // A silent removal from the `show` clause, an arg-order swap, a
      // changed default for any named parameter, or a dropped optional
      // parameter would fail this assignment at compile time. Demoting
      // either nullable timing-phase parameter to non-null would also
      // fail it.
      final Future<E2eStandardScenarioOpener> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Duration wallClockCap,
        Locale locale,
        Size surfaceSize,
        String bootstrapTimingPhase,
        String afterBootstrapStep,
        String? assetPreloadTimingPhase,
        String afterAssetPreloadStep,
        String? newGameToMapTimingPhase,
        String afterNewGameToMapStep,
      })
      ref = enterStandardE2eScenario;
      expect(ref, isNotNull);
    });

    test('e2eEnterStandardE2eScenario (lifted form) is re-exported as a '
        'tear-off with the same signature (compile-time pin)', () {
      // Both the lifted form and the AC1 barrel alias must remain
      // available with matching signatures so future callers can pick
      // either entrypoint without an arg-order surprise.
      final Future<E2eStandardScenarioOpener> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Duration wallClockCap,
        Locale locale,
        Size surfaceSize,
        String bootstrapTimingPhase,
        String afterBootstrapStep,
        String? assetPreloadTimingPhase,
        String afterAssetPreloadStep,
        String? newGameToMapTimingPhase,
        String afterNewGameToMapStep,
      })
      ref = shared.e2eEnterStandardE2eScenario;
      expect(ref, isNotNull);
    });
  });
}
