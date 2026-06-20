import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Awaits [panelRoot] mounting after a panel-opener rail/marker tap, using
/// the canonical "fast-check, single pump, bounded poll" recipe shared by
/// the three panel openers.
///
/// Lifts the post-tap mount-check body that
/// [e2eOpenCivilianPanel] and [e2eOpenNavalPanel] previously duplicated
/// inside their inner `tryOpen` closures, and that [e2eOpenProductionPanel]
/// previously inlined directly after [e2eEnsureVisibleAndTapHitTestable].
/// Before this lift the three openers each spelled the same three-step
/// recipe (immediate hit-check → one explicit pump → bounded
/// [e2ePumpUntilConditionOrIdle]) with different phase names and timeouts;
/// drift between them would mean the production opener could spin its
/// outer loop while the civilian opener short-circuited, or vice versa.
/// Centralising the recipe behind one helper keeps the three openers
/// byte-equivalent on the post-tap path. Refs GitHub #2336 AC1 / AC2 /
/// AC10 (deferred slice from PR #2782).
///
/// Lives in a dedicated file so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines). The barrel
/// re-exports this entrypoint so consumers depend on `e2e_test_shared.dart`
/// (or the AC1 `e2e_helpers.dart` barrel) only.
///
/// Contract:
///
/// - Returns `true` immediately when [panelRoot] already resolves to at
///   least one element. No pump is issued and no perf event is emitted
///   so the no-pop common case (panel mounted synchronously in the same
///   build frame as the rail tap) costs the same as a raw
///   `panelRoot.evaluate().isNotEmpty` probe.
/// - Otherwise issues exactly one `await tester.pump()` (no duration so
///   the engine settles whatever microtasks the rail tap scheduled) and
///   re-checks. A successful mount on the post-pump check returns `true`
///   without entering [e2ePumpUntilConditionOrIdle], keeping the fast
///   path identical to the pre-lift inline civilian/naval recipe.
/// - When the panel still has not mounted, delegates to
///   [e2ePumpUntilConditionOrIdle] with the provided [timeout], [perf],
///   and [phaseName]. That helper polls with adaptive backoff (25 → 100
///   ms cap) and emits `result=immediate|met|timeout` perf timings on
///   [perf]. Returns whatever the bounded poll reports; never throws on
///   timeout so the opener's outer loop can dismiss transient overlays
///   and retry the rail/marker branch on the next iteration.
/// - The [timeout] is passed verbatim to [e2ePumpUntilConditionOrIdle];
///   callers select the per-opener cap (3 s for civilian/naval, 5 s for
///   production) by passing it explicitly so the helper does not have
///   to encode opener-specific defaults.
Future<bool> e2eAwaitPanelMountAfterOpenerTap(
  WidgetTester tester,
  Finder panelRoot, {
  required Duration timeout,
  E2ePerfLog? perf,
  required String phaseName,
}) async {
  if (panelRoot.evaluate().isNotEmpty) {
    return true;
  }
  await tester.pump();
  if (panelRoot.evaluate().isNotEmpty) {
    return true;
  }
  return e2ePumpUntilConditionOrIdle(
    tester,
    () => panelRoot.evaluate().isNotEmpty,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}
