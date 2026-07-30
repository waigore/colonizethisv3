// handlePopRoute fallback pins for
// `e2e_dismiss_ct_dialog_shell_broad_sweep_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_broad_sweep_fixtures.dart';
import 'dismiss_widget_tester_harness.dart';

void registerDismissBroadSweepPopRouteGroup() {
  group(
    'e2eDismissCtDialogShellBroadSweepIfPresent — handlePopRoute fallback',
    () {
      testWidgets(
        'falls back to handlePopRoute when no candidate is hit-testable and '
        'still returns true',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            wrapDismissMaterial(
              const DismissPostFrameDialogHost(
                dialogBuilder: dismissBroadSweepRouteShellNoCandidatesBuilder,
              ),
            ),
          );
          await pumpDismissOverlaySettle(tester);
          expect(find.byType(CtDialogShell), findsOneWidget);

          final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
            tester,
          );
          await pumpDismissPostTapSettle(tester);

          expect(
            dismissed,
            isTrue,
            reason:
                'handlePopRoute fallback must be reported as a successful '
                'dismissal attempt — the legacy inline block had no '
                '`false` branch when the shell was mounted.',
          );
          expect(
            find.byType(CtDialogShell),
            findsNothing,
            reason:
                'handlePopRoute() must close the CtDialogShell when no '
                'candidate is hit-testable. A regression that skipped the '
                'fallback would leave the shell mounted and starve the '
                'subsequent phase.',
          );
        },
      );
    },
  );
}
