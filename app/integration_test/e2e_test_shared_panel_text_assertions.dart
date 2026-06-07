import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';
import 'e2e_test_shared_bootstrap.dart' show e2eCollectTextPreorder;

/// Default `phaseName` forwarded into [e2eWaitUntilFound] when
/// [e2eExpectPanelTextsMatchSnapshot] is invoked without an explicit override.
///
/// The literal `'wait_until_found_panel_for_text_assertion'` is captured here
/// as a public constant so a silent rename can be detected by the
/// `app/test/e2e_expect_panel_texts_match_snapshot_test.dart` widget-test
/// pin instead of only by AC8 timing tables on the slow CI lane (Refs GitHub
/// #2336 AC1 / AC2).
const String kE2eDefaultExpectPanelTextsPhase =
    'wait_until_found_panel_for_text_assertion';

/// Default `timeout` for the [e2eWaitUntilFound] gate inside
/// [e2eExpectPanelTextsMatchSnapshot].
///
/// Mirrors the 20-second budget used by the pre-lift inline closures in
/// `new_game_full_turn_e2e_test.dart` (`expectCivilianPanelTexts`,
/// `expectNavalPanelTexts`, `expectProductionPanelTexts`) and the inline
/// 30-second wait in `new_game_capital_panel_e2e_test.dart` for the
/// province panel — keeping the 20s default keeps the full-turn budget
/// unchanged; capital-panel callers pass their explicit 30s timeout.
const Duration kE2eDefaultExpectPanelTextsTimeout = Duration(seconds: 20);

/// Default bounded budget for the post-panel-mount poll that waits for the
/// caller-provided `snapshotReader` to return non-null inside
/// [e2eExpectPanelTextsMatchSnapshot].
///
/// The pre-lift inline closures in `new_game_full_turn_e2e_test.dart` and
/// `new_game_capital_panel_e2e_test.dart` read the matching `ctE2e*` global
/// **after** the panel-root `waitUntilFound` had completed, so the snapshot
/// setter had at least one extra pump-frame to fire (the panel-root mount
/// itself drove the next build, during which the panel's first frame
/// invoked `updateCtE2e*PanelSnapshotIfEnabled`). The post-lift signature
/// captured the snapshot value at call time, which races against
/// `addPostFrameCallback` / `setState`-driven setters: the panel-root
/// finder can become non-empty in the same frame the snapshot setter is
/// scheduled for, leaving the captured value `null` when the assertion
/// runs. The bounded poll restores the pre-lift semantics — read the
/// global *after* the panel mounts, with a small adaptive window for the
/// post-frame setter to fire (Refs GitHub #2336 AC5 / AC10 — no new
/// flakiness — and the race surfaced under
/// `xvfb-run` Linux desktop).
///
/// Two seconds is intentionally generous compared with the typical
/// single-frame turnaround so a slow CI runner that drops a frame mid-mount
/// still settles inside the budget without re-introducing the false
/// `null snapshot` failure. Callers can override via the
/// `snapshotReaderTimeout` parameter — the production-panel scenario
/// passes 30 s when the panel mounts under heavier app-side work.
const Duration kE2eDefaultExpectPanelTextsSnapshotReaderTimeout = Duration(
  seconds: 2,
);

/// Default `phaseName` forwarded into the bounded snapshot-reader poll
/// inside [e2eExpectPanelTextsMatchSnapshot].
///
/// Carries a distinct phase label (separate from the panel-root
/// `waitUntilFound` slice) so AC8 timing tables can attribute the
/// post-mount snapshot-population wait independently of the panel-root
/// mount wait. A regression that merged the two would either hide a
/// growing post-mount setter latency or attribute it to the unrelated
/// rail/marker wait bucket.
const String kE2eDefaultExpectPanelTextsSnapshotReaderPhase =
    'pump_until_panel_snapshot_populated';

/// Asserts that the rendered widget tree under [panelRootKey] matches the
/// expected text lines built by [buildExpected] (or, when a panel can be in
/// one of two valid steady-state variants, either [buildExpected] **or**
/// [buildAlternativeExpected]).
///
/// Lifted from the inline `expectCivilianPanelTexts` / `expectNavalPanelTexts`
/// / `expectProductionPanelTexts` closures in
/// `new_game_full_turn_e2e_test.dart` and the inline province-panel
/// assertion block in `new_game_capital_panel_e2e_test.dart` so the
/// `wait root → expect snapshot non-null → collectTextPreorder →
/// orderedEquals` recipe ships once per repo and is unit-pinned in
/// `app/test/e2e_expect_panel_texts_match_snapshot_test.dart`
/// (Refs GitHub #2336 AC1 / AC2).
///
/// The integration suite cannot validate this directly today
/// (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test pin
/// carries the behavioural contract.
///
/// Contract:
///
/// - Awaits [e2eWaitUntilFound] for [panelRootKey] using [phaseName]
///   (default [kE2eDefaultExpectPanelTextsPhase]) and [timeout]
///   (default [kE2eDefaultExpectPanelTextsTimeout]). [perf] is forwarded
///   verbatim so callers keep their attribution labels.
/// - After the panel root mounts, runs a bounded
///   [e2ePumpUntilConditionOrIdle] poll waiting for
///   `snapshotReader()` to return non-null — the panel-mirror setter runs
///   in the panel's first build / post-frame callback, which can land in
///   the same frame as the panel-root finder becoming non-empty. Without
///   this re-read the pre-lift inline behaviour (read the matching
///   `ctE2e*` global **after** the wait completed) would not be
///   preserved and the assertion would race the setter. The poll uses
///   [snapshotReaderTimeout] (default
///   [kE2eDefaultExpectPanelTextsSnapshotReaderTimeout] = 2 s) and emits
///   a dedicated [snapshotReaderPhaseName] timing slice (default
///   [kE2eDefaultExpectPanelTextsSnapshotReaderPhase]) so AC8 dashboards
///   keep post-mount setter latency separate from the panel-root mount
///   slice.
/// - Asserts the re-read `snapshotReader()` is not null with a `reason:`
///   that names [panelRootKey]; the pre-lift closures all relied on the
///   matching global panel snapshot being populated before reading
///   expected texts (`civilianUnitsPanelExpectedTexts(snap!, l10n)` etc.),
///   so a regression that called this helper before the panel finished
///   priming its snapshot would fail here with a deterministic message
///   instead of a confusing `null!` cast deeper in the builder.
/// - Calls [e2eCollectTextPreorder] on the panel root element to populate
///   `actual`, then compares with `orderedEquals(buildExpected())`.
/// - When [ignoreActualTexts] is non-empty, every collected text equal to
///   one of its entries is dropped from `actual` **before** the ordered
///   comparison. This normalizes away **host-width-dependent** decorative
///   labels that the canonical mirror intentionally omits — specifically the
///   dense fleet-action labels (`Move` / `Split`) on the naval panel, which
///   render as icon-only at the narrow macOS test host but as `Icon + Text`
///   on the wider Linux desktop integration host (the dense action cluster
///   crosses the `UnitsEntityActionRow` icon-only breakpoint at the realized
///   1280-wide viewport). Filtering is **narrow and order-preserving** (it
///   removes only the named labels and keeps `orderedEquals` over everything
///   else), so it is not the broad/contains weakening
///   `colonizethis-e2e-ui-stability.mdc` cautions against; it keeps the
///   assertion deterministic across hosts without weakening any other line
///   (Refs GitHub #2336 AC6 — `full_turn` naval-panel host portability).
/// - When [buildAlternativeExpected] is non-`null`, the assertion uses
///   `anyOf(orderedEquals(buildExpected()), orderedEquals(buildAlternativeExpected()))`
///   so panels that can settle in either of two deterministic variants
///   (the naval panel `fleetTilesExpanded: true` path falls back to the
///   collapsed mirror when the post-tap expansion has not finished
///   re-rendering) keep their pre-lift `anyOf` semantics.
///
/// [snapshotReader], [buildExpected], and [buildAlternativeExpected] are
/// zero-arg closures so callers can read the matching `ctE2e*` mirror at
/// the moment of evaluation (rather than capturing a stale value at call
/// time) and so the helper remains free of generics — every snapshot type
/// (`CtE2eCivilianPanelSnapshot`, `CtE2eNavalPanelSnapshot`,
/// `CtE2eProductionPanelSnapshot`, `CtE2eLastPanelSnapshot`) reuses the
/// same composition.
Future<void> e2eExpectPanelTextsMatchSnapshot(
  WidgetTester tester, {
  required Key panelRootKey,
  required Object? Function() snapshotReader,
  required List<String> Function() buildExpected,
  String phaseName = kE2eDefaultExpectPanelTextsPhase,
  Duration timeout = kE2eDefaultExpectPanelTextsTimeout,
  Duration snapshotReaderTimeout =
      kE2eDefaultExpectPanelTextsSnapshotReaderTimeout,
  String snapshotReaderPhaseName =
      kE2eDefaultExpectPanelTextsSnapshotReaderPhase,
  E2ePerfLog? perf,
  List<String> Function()? buildAlternativeExpected,
  List<String> ignoreActualTexts = const [],
}) async {
  await e2eWaitUntilFound(
    tester,
    find.byKey(panelRootKey),
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => snapshotReader() != null,
    timeout: snapshotReaderTimeout,
    perf: perf,
    phaseName: snapshotReaderPhaseName,
  );
  expect(
    snapshotReader(),
    isNotNull,
    reason:
        'snapshot for panel root key $panelRootKey must be populated before '
        'expecting rendered texts; a null snapshot indicates the panel did '
        'not finish priming its CtE2e* mirror before the assertion ran.',
  );
  final collected = <String>[];
  e2eCollectTextPreorder(
    tester.element(find.byKey(panelRootKey)),
    collected,
  );
  final actual = ignoreActualTexts.isEmpty
      ? collected
      : collected.where((t) => !ignoreActualTexts.contains(t)).toList();
  if (buildAlternativeExpected == null) {
    expect(actual, orderedEquals(buildExpected()));
    return;
  }
  expect(
    actual,
    anyOf(
      orderedEquals(buildExpected()),
      orderedEquals(buildAlternativeExpected()),
    ),
  );
}
