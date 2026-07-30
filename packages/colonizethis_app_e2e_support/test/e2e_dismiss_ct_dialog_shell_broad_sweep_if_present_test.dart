/// Pins the widget-tree contract of
/// [e2eDismissCtDialogShellBroadSweepIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its [CtDialogShell] branch (every panel-opener pre-tap dismiss
/// across the three integration scenarios). The pre-lift inline block was a
/// 26-line recipe duplicated inside [e2eDismissTransientUi] and not
/// independently testable. After this lift, every overlay branch of the
/// broad-spectrum sweep delegates to a single-source-of-truth shared helper —
/// no inline dismissal recipes remain in [e2eDismissTransientUi]'s overlay
/// branches.
///
/// This pin guards:
///
/// - Priority ordering of the close-candidate list (`Cancel` text → `Close`
///   text → [Icons.close] → [Icons.arrow_back]). A silent reorder would
///   change which control gets tapped when more than one candidate is
///   hit-testable — for example a dialog with both `Cancel` and `Close`
///   should prefer `Cancel` to avoid accidentally confirming the
///   destructive default action that legacy [CtDialogShell] surfaces
///   sometimes wired to `Close`.
/// - Hit-testable filter on each candidate. A candidate finder that
///   matched without `.hitTestable()` would tap a control covered by a
///   transient overlay and silently miss the dismiss.
/// - The [tester.binding.handlePopRoute] fallback. When **none** of the
///   candidates are hit-testable the helper falls through to
///   `handlePopRoute()` rather than returning `false` — the legacy inline
///   block had no `false` branch when a [CtDialogShell] was mounted.
/// - The `dismiss_ct_dialog_shell_broad_sweep_calls` perf counter is
///   bumped once per **successful** dismissal attempt and **not** bumped
///   on the no-shell short-circuit.
/// - The default 2 s [kE2eDefaultCtDialogShellBroadSweepDismissTimeout]
///   budget — a silent drift here would either inflate the per-call
///   dismiss window (regressing AC9 aggregate wall-clock) or shrink it
///   (risking false negatives when the dismiss animation runs slow under
///   load).
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/dismiss_broad_sweep_baseline_group.dart';
import 'support/dismiss_broad_sweep_counter_group.dart';
import 'support/dismiss_broad_sweep_hit_testable_group.dart';
import 'support/dismiss_broad_sweep_pop_route_group.dart';
import 'support/dismiss_broad_sweep_priority_group.dart';

void main() {
  suppressLogsForTests();

  registerDismissBroadSweepBaselineGroup();
  registerDismissBroadSweepPriorityGroup();
  registerDismissBroadSweepHitTestableGroup();
  registerDismissBroadSweepPopRouteGroup();
  registerDismissBroadSweepCounterGroup();
}
