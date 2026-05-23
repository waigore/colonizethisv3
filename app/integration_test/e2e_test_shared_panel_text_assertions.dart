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
/// - Asserts [snapshot] is not null with a `reason:` that names
///   [panelRootKey]; the pre-lift closures all relied on the matching
///   global panel snapshot being populated before reading expected
///   texts (`civilianUnitsPanelExpectedTexts(snap!, l10n)` etc.), so a
///   regression that called this helper before the panel finished
///   priming its snapshot would fail here with a deterministic message
///   instead of a confusing `null!` cast deeper in the builder.
/// - Calls [e2eCollectTextPreorder] on the panel root element to populate
///   `actual`, then compares with `orderedEquals(buildExpected())`.
/// - When [buildAlternativeExpected] is non-`null`, the assertion uses
///   `anyOf(orderedEquals(buildExpected()), orderedEquals(buildAlternativeExpected()))`
///   so panels that can settle in either of two deterministic variants
///   (the naval panel `fleetTilesExpanded: true` path falls back to the
///   collapsed mirror when the post-tap expansion has not finished
///   re-rendering) keep their pre-lift `anyOf` semantics.
///
/// [buildExpected] and [buildAlternativeExpected] are zero-arg builders so
/// callers can capture the (now non-null) panel snapshot in a closure and
/// keep the helper free of generics — every snapshot type
/// (`CtE2eCivilianPanelSnapshot`, `CtE2eNavalPanelSnapshot`,
/// `CtE2eProductionPanelSnapshot`, `CtE2eLastPanelSnapshot`) reuses the
/// same composition.
Future<void> e2eExpectPanelTextsMatchSnapshot(
  WidgetTester tester, {
  required Key panelRootKey,
  required Object? snapshot,
  required List<String> Function() buildExpected,
  String phaseName = kE2eDefaultExpectPanelTextsPhase,
  Duration timeout = kE2eDefaultExpectPanelTextsTimeout,
  E2ePerfLog? perf,
  List<String> Function()? buildAlternativeExpected,
}) async {
  await e2eWaitUntilFound(
    tester,
    find.byKey(panelRootKey),
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
  expect(
    snapshot,
    isNotNull,
    reason:
        'snapshot for panel root key $panelRootKey must be populated before '
        'expecting rendered texts; a null snapshot indicates the panel did '
        'not finish priming its CtE2e* mirror before the assertion ran.',
  );
  final actual = <String>[];
  e2eCollectTextPreorder(
    tester.element(find.byKey(panelRootKey)),
    actual,
  );
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
