// Hit-testable filter pins for
// `e2e_dismiss_ct_dialog_shell_broad_sweep_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_broad_sweep_fixtures.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissBroadSweepHitTestableGroup() {
  group('e2eDismissCtDialogShellBroadSweepIfPresent — hit-testable filter', () {
    testWidgets('taps a later candidate when the higher-priority candidate is '
        'covered (non-hit-testable)', (WidgetTester tester) async {
      var closeTaps = 0;
      await tester.pumpWidget(
        wrapDismissCentered(
          DismissBroadSweepCoveredFirstActionShell(
            firstLabel: 'Cancel',
            secondLabel: 'Close',
            onTapSecond: () => closeTaps++,
          ),
        ),
      );
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(
        find.text('Cancel'),
        findsOneWidget,
        reason:
            'Fixture must keep the Cancel candidate mounted (covered by '
            'an opaque overlay) so the hit-testable filter has a '
            'non-trivial choice to make.',
      );
      expect(find.text('Close'), findsOneWidget);

      final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
        tester,
      );

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true even when the higher-priority '
            'Cancel is non-hit-testable, by tapping the hit-testable '
            'Close fallback.',
      );
      expect(
        closeTaps,
        1,
        reason:
            'A regression that dropped the hit-testable filter would '
            'tap the covered Cancel and never reach Close; the lifted '
            'form must tap exactly the visible Close button.',
      );
    });
  });
}
