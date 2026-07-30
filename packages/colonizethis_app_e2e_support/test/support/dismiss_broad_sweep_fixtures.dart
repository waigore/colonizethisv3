// CtDialogShell broad-sweep dismiss mirror fixtures (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';

import 'dismiss_widget_tester_harness.dart';

/// Surfaces a [CtDialogShell] whose contents include the [firstLabel] text
/// covered by an opaque [AbsorbPointer] overlay (so the first labelled
/// candidate is mounted but non-hit-testable) plus a hit-testable
/// [secondLabel] action.
class DismissBroadSweepCoveredFirstActionShell extends StatelessWidget {
  const DismissBroadSweepCoveredFirstActionShell({
    required this.firstLabel,
    required this.onTapSecond,
    required this.secondLabel,
  });

  final String firstLabel;
  final String secondLabel;
  final VoidCallback onTapSecond;

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 48,
            child: absorbPointerCover(
              child: TextButton(onPressed: () {}, child: Text(firstLabel)),
            ),
          ),
          TextButton(onPressed: onTapSecond, child: Text(secondLabel)),
        ],
      ),
    );
  }
}

/// Top-level [WidgetBuilder] tear-off used by the route-based handlePopRoute
/// fallback pin. Surfaces a [CtDialogShell] with **no** labelled candidates
/// so the helper has to fall through to `tester.binding.handlePopRoute()`.
Widget dismissBroadSweepRouteShellNoCandidatesBuilder(BuildContext context) {
  return const CtDialogShell(child: Text('Nothing tappable'));
}

/// Top-level [WidgetBuilder] tear-off used by the route-based perf-counter
/// handlePopRoute fallback pin.
Widget dismissBroadSweepRouteShellNoCandidatesPerfBuilder(
  BuildContext context,
) {
  return const CtDialogShell(child: Text('Nothing tappable for perf'));
}
