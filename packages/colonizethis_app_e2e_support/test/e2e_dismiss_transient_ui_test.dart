// Pins the branch behaviour of `e2eDismissTransientUi` (Refs GitHub #2336
// AC2 / AC5 — shared E2E helper hardening).
//
// `e2eDismissTransientUi` is one of the most-called shared helpers across
// every integration_test (panel openers, fleet/turn loops, region tab
// flips). Its dismissal path is a multi-branch waterfall: GameStartIntro
// blocker → SnackBar action → top-level OK → AlertDialog labelled close →
// AlertDialog pop fallback → BottomSheet → CtDialogShell. A tuning
// regression that silently reorders or skips any branch would inflate every
// scenario's wall-clock cost (and, in the AlertDialog/SnackBar cases, can
// strand transient UI so subsequent opener calls time out).
//
// `integration_test/` is not part of the PR `quality` workflow (SPEC §
// `e2e-integration-tests.md`), so this widget-test layer is the only
// per-PR pin for the dismissal contract. Tests mirror the structure of
// the existing helper pins for sibling helpers
// (`app/test/e2e_close_bottom_sheet_test.dart`,
// `app/test/e2e_open_panel_prepump_test.dart`,
// `app/test/e2e_advance_game_start_intro_test.dart`).
//
// Coverage layers:
//   - Pre-pump short-circuit: an empty widget tree must not pay even one
//     idle pump (mirrors the AC5 prepump short-circuit pins for the panel
//     openers).
//   - SnackBar with action: tapping the SnackBar action removes the
//     SnackBar from the tree before the helper returns.
//   - Top-level OK button: tapping OK removes the OK label.
//   - AlertDialog with `Close` label: helper prefers the labelled close
//     button over the generic pop-route fallback.
//   - AlertDialog with no labelled close button: helper falls through to
//     `handlePopRoute` and clears the dialog.
//
// The `CtDialogShell` and `BottomSheet` branches are pinned in their own
// helpers (`e2e_close_bottom_sheet_test.dart` and the existing
// integration paths) and rely on Flame asset loading, so they are not
// exercised again here.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/dismiss_transient_ui_baseline_group.dart';
import 'support/dismiss_transient_ui_perf_group.dart';
import 'support/dismiss_transient_ui_perf_results_group.dart';

void main() {
  suppressLogsForTests();
  registerDismissTransientUiBaselineGroup();
  registerDismissTransientUiPerfGroup();
  registerDismissTransientUiPerfResultsGroup();
}
