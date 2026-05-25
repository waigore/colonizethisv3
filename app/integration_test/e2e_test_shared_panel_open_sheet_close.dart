import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Closes a conflicting [BottomSheet] sitting on top of the empire rail and
/// then awaits the opener rail (or fallback marker) becoming visible so the
/// outer panel-opener loop can attempt its next rail/marker tap on a clean
/// surface.
///
/// Lifts the byte-equivalent post-sheet-close cleanup block that
/// [e2eOpenCivilianPanel] and [e2eOpenNavalPanel] each inlined inside the
/// `if (find.byType(BottomSheet).evaluate().isNotEmpty)` branch of their
/// outer adaptive-poll loop. Before this lift the two openers each spelled
/// the same three-step recipe (close sheet → poll until sheet cleared →
/// poll until rail/marker hit-testable) with different phase-name suffixes
/// (`civilian_opener` vs `naval_opener`); drift between them could mean a
/// future refactor that tightened one path silently regressed the other.
/// Centralising the recipe behind one helper keeps the two openers
/// byte-equivalent on the post-sheet-close cleanup path. Refs GitHub #2336
/// AC1 / AC2 / AC10 (follow-up slice from PR #2782 after
/// [e2eAwaitPanelMountAfterOpenerTap]).
///
/// Lives in a dedicated file so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines), matching the
/// extraction pattern already used by
/// `e2e_test_shared_panel_open_post_tap_probe.dart`. The barrel re-exports
/// this entrypoint so consumers depend on `e2e_test_shared.dart` (or the
/// AC1 `e2e_helpers.dart` barrel) only.
///
/// Production has no `markerButton` concept and only awaits its sheet
/// cleared via a single 600 ms `e2ePumpUntilConditionOrIdle` (the rail tap
/// retries on the next outer-loop iteration) so the production opener
/// keeps its tighter cleanup body untouched by this lift.
///
/// Contract:
///
/// - Delegates the actual sheet-pop to [e2eCloseBottomSheet] with the
///   provided [perf] and [bottomSheetCloseTimeout], byte-equivalent to
///   the inline call the two openers made.
/// - Polls [find.byType(BottomSheet)] until it resolves to zero elements
///   via [e2ePumpUntilConditionOrIdle] with [sheetClearTimeout] and
///   [afterSheetClearPhase]. The outer phase label is forwarded verbatim
///   so downstream `E2E_TIMING|phase=...` log scrapers and dashboards
///   keep attributing post-sheet-close settle time to the calling opener
///   (civilian vs naval) — a silent rename here would orphan that
///   telemetry. `e2ePumpUntilConditionOrIdle` does not throw on timeout
///   so a sheet that lingers past the cap defers to the outer opener
///   loop's next iteration (best-effort settle, matching the pre-lift
///   inline behaviour).
/// - Polls [primary] / [secondary] hit-testability via
///   [e2ePumpUntilConditionOrIdle] with [awaitOpenerTimeout] and
///   [awaitOpenerPhase]. The poll evaluates the predicate before its
///   first pump so a rail/marker already on-screen short-circuits at the
///   pre-lift fast-path cost. The check uses `hitTestable()` so a rail
///   button still covered by a leftover overlay (typical when the sheet
///   close races a transient snackbar) is treated as not-yet-ready, the
///   same condition the inline body used.
/// - When [secondary] is `null`, the rail/marker poll evaluates only
///   [primary] hit-testability; reserved for openers that have no
///   marker fallback (currently unused at the call site because both
///   civilian and naval pass both finders, but the parameter mirrors
///   the symmetric [e2eAwaitPanelOpenerRailHitTestable] signature so
///   future openers can adopt this helper without growing a parallel
///   variant).
/// - Returns `void`; the caller is responsible for resetting its
///   `panelPollMs` cadence to the post-action reset (25 ms) and issuing
///   the `continue` that re-enters the outer adaptive-poll loop. Both
///   the cadence reset and the `continue` are caller-local control
///   flow that the helper cannot encode without leaking the loop
///   structure of the opener function it serves.
Future<void> e2eClosePanelOpenerSheetAndAwaitOpener(
  WidgetTester tester, {
  required Finder primary,
  Finder? secondary,
  required String afterSheetClearPhase,
  required String awaitOpenerPhase,
  E2ePerfLog? perf,
  Duration bottomSheetCloseTimeout = kE2eDefaultBottomSheetCloseTimeout,
  Duration sheetClearTimeout = const Duration(seconds: 2),
  Duration awaitOpenerTimeout = const Duration(seconds: 3),
}) async {
  await e2eCloseBottomSheet(
    tester,
    perf: perf,
    overallTimeout: bottomSheetCloseTimeout,
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => find.byType(BottomSheet).evaluate().isEmpty,
    timeout: sheetClearTimeout,
    perf: perf,
    phaseName: afterSheetClearPhase,
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () =>
        primary.hitTestable().evaluate().isNotEmpty ||
        (secondary != null && secondary.hitTestable().evaluate().isNotEmpty),
    timeout: awaitOpenerTimeout,
    perf: perf,
    phaseName: awaitOpenerPhase,
  );
}
