import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Composes a panel-opener `tryOpen` attempt: short-circuits when [panelRoot]
/// is already hit-testable, otherwise issues a defensive
/// [e2eEnsureVisibleAndTapHitTestable] tap on [trigger] and awaits
/// [panelRoot] mounting via [e2eAwaitPanelMountAfterOpenerTap].
///
/// Lifts the byte-equivalent inner `tryOpen` closure that
/// [e2eOpenCivilianPanel] and [e2eOpenNavalPanel] each declared inside their
/// outer adaptive-poll loop. Before this lift the two openers each spelled
/// the same three-step recipe inline:
///
///   1. `if (panel.hitTestable().evaluate().isNotEmpty) return true;`
///   2. `if (!await e2eEnsureVisibleAndTapHitTestable(tester, trigger)) {
///       return false; }`
///   3. `return e2eAwaitPanelMountAfterOpenerTap(tester, panel, ...);`
///
/// with different per-opener panel-root finders and post-tap mount
/// `phaseName` strings. Drift between the two — for example, dropping the
/// pre-tap `panelRoot` short-circuit on naval but keeping it on civilian —
/// would surface as a per-call wall-clock regression that
/// `app_e2e_linux` cannot catch (the lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). Centralising the recipe
/// behind one helper keeps the two openers byte-equivalent on the inner
/// `tryOpen` path. Refs GitHub #2336 AC1 / AC2 / AC10 (follow-up slice from
/// PR #2782 after [e2eAwaitPanelMountAfterOpenerTap]).
///
/// The production opener does not adopt this helper because its outer loop
/// already short-circuits on `panelRoot.evaluate().isNotEmpty` at the top of
/// every iteration (vs civilian/naval which short-circuit only on the
/// `hitTestable` predicate inside the inner closure). Reshaping production
/// to fit one shared inner-attempt would change the production
/// outer-loop's perf-timing emit position, so production keeps its inline
/// `e2eEnsureVisibleAndTapHitTestable` + [e2eAwaitPanelMountAfterOpenerTap]
/// pair untouched by this lift.
///
/// Lives in a dedicated file so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines), matching the
/// extraction pattern already used by
/// `e2e_test_shared_panel_open_post_tap_probe.dart` and
/// `e2e_test_shared_panel_open_sheet_close.dart`. The barrel re-exports
/// this entrypoint so consumers depend on `e2e_test_shared.dart` (or the
/// AC1 `e2e_helpers.dart` barrel) only.
///
/// Contract:
///
/// - Returns `true` immediately when [panelRoot] is already hit-testable.
///   The fast-path matches the pre-lift inline civilian/naval recipe and
///   is critical for the post-sheet-close iteration where the panel can
///   already be rebuilt before the opener loop reaches its rail-tap arm.
/// - Calls [e2eEnsureVisibleAndTapHitTestable] on [trigger]; returns
///   `false` when the trigger resolves to zero elements (no tap issued).
///   The caller's outer loop is then responsible for retrying the
///   rail/marker arm on the next iteration.
/// - On a successful tap, delegates to [e2eAwaitPanelMountAfterOpenerTap]
///   with the supplied [mountTimeout], [perf], and [mountPhaseName]. That
///   helper polls with adaptive backoff (25 → 100 ms cap) and emits
///   `result=immediate|met|timeout` perf timings on [perf]. The helper
///   never escalates a timeout into a `fail()` call so the outer opener
///   loop can dismiss transient overlays and retry rail/marker on the
///   next iteration.
/// - The [mountTimeout] is forwarded verbatim; civilian and naval each
///   pass `Duration(seconds: 3)` matching their pre-lift constants.
Future<bool> e2eOpenerTapTriggerAndAwaitMount(
  WidgetTester tester, {
  required Finder trigger,
  required Finder panelRoot,
  required Duration mountTimeout,
  required String mountPhaseName,
  E2ePerfLog? perf,
}) async {
  if (panelRoot.hitTestable().evaluate().isNotEmpty) {
    return true;
  }
  if (!await e2eEnsureVisibleAndTapHitTestable(tester, trigger)) {
    return false;
  }
  return e2eAwaitPanelMountAfterOpenerTap(
    tester,
    panelRoot,
    timeout: mountTimeout,
    perf: perf,
    phaseName: mountPhaseName,
  );
}
