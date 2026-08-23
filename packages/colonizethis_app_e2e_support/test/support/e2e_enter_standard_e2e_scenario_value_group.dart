library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

void registerE2eEnterStandardE2eScenarioValueGroup() {
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
}
