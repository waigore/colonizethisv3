/// Pins the widget-tree contract of
/// [e2eAwaitExploreEnabledFromCivilianPanel]
/// (`app/integration_test/e2e_test_shared_bundled_explore_retry.dart`).
///
/// The post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `awaitExploreEnabledFromCivilianPanel` to bridge
/// the strict bundled-Explore assertion (`anyExplorerHasEnabledExploreAssignFleet`)
/// with the bounded next-turn retry window that absorbs CI suggestion-
/// propagation lag.
///
/// A silent regression here would either:
///
///   - Drop the per-iteration `perf.bumpCounter(...)` call and orphan
///     every `E2E_COUNTER|...|name=bundled_explore_retry_iterations|...`
///     scraper / dashboard keyed on the bounded retry budget — hiding
///     Bottleneck 5 regressions.
///   - Flip the boolean encoding (return `true` on bounded exhaustion or
///     `false` on initial-check success) and silently invert the
///     post-bundle Explore-enabled assertion.
///   - Bump the default [kE2eDefaultBundledExploreMaxTurnRetries] (8) or
///     rename [kE2eDefaultBundledExploreRetryIterationCounter]
///     (`bundled_explore_retry_iterations`) and orphan every dashboard
///     keyed on the legacy literal.
///   - Skip the retry loop entirely on a `false` initial check —
///     converting a recoverable lag-window regression into an immediate
///     `fail()` and inflating the post-bundle scenario's failure rate
///     past the bounded-retry tolerance #2336 / #1869 absorbs.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5.
library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/await_explore_enabled_barrel_group.dart';
import 'support/await_explore_enabled_initial_group.dart';
import 'support/await_explore_enabled_zero_retry_group.dart';

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  group('e2eAwaitExploreEnabledFromCivilianPanel — default constants', () {
    test('kE2eDefaultBundledExploreMaxTurnRetries preserves the legacy '
        'inline `maxBoundedTurnRetries = 8` literal', () {
      expect(
        kE2eDefaultBundledExploreMaxTurnRetries,
        8,
        reason:
            'Pre-lift fleet `for (var retryIdx = 0; ... retryIdx < 8; ...)` '
            'callers and downstream wall-clock budgeting expect the bounded '
            'retry window to remain at exactly 8 turns. A silent change '
            'here would either inflate the post-bundle Explore wall clock '
            'past the `_kMaxUiResponseWait (5s)` cap #2336 is reducing or '
            'shrink the window below the CI suggestion-propagation lag '
            'tolerance #1869 / Bottleneck 5 absorbs.',
      );
    });

    test('kE2eDefaultBundledExploreRetryIterationCounter preserves the '
        'legacy inline `bumpCounter` name', () {
      expect(
        kE2eDefaultBundledExploreRetryIterationCounter,
        'bundled_explore_retry_iterations',
        reason:
            'Pre-lift `perf.bumpCounter("bundled_explore_retry_iterations")` '
            'callers and downstream `E2E_COUNTER|test=...|name=...` '
            'log scrapers / AC8 dashboards expect this exact literal. A '
            'silent rename would orphan every dashboard counting bounded '
            'retry iterations and hide Bottleneck 5 regressions.',
      );
    });
  });

  registerAwaitExploreEnabledInitialGroup(l10n);
  registerAwaitExploreEnabledZeroRetryGroup(l10n);
  registerAwaitExploreEnabledBarrelGroup(l10n);
}
