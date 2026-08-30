// Asserts the pop-once-then-poll contract of `e2eCloseBottomSheet` (Refs
// GitHub #2336 pump-reduction slice). The previous implementation called
// `tester.binding.handlePopRoute` on every poll iteration, racing the
// dismiss animation; the rewritten helper pops once and polls with
// `e2ePumpUntilConditionOrIdle` so the loop exits the moment the bottom
// sheet leaves the widget tree.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'support/close_bottom_sheet_host.dart';
import 'support/e2e_widget_pump_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('e2eCloseBottomSheet returns immediately when no sheet exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapE2eApp(SizedBox()));
    final sw = Stopwatch()..start();
    await e2eCloseBottomSheet(tester);
    expect(
      sw.elapsed < const Duration(milliseconds: 100),
      isTrue,
      reason:
          'No-sheet calls must short-circuit before pumping any frame so the '
          'helper does not amplify caller cost when nothing is open.',
    );
  });

  testWidgets(
    'e2eCloseBottomSheet dismisses a real BottomSheet within budget',
    (WidgetTester tester) async {
      await tester.pumpWidget(wrapE2eApp(const CloseBottomSheetHost()));
      // The post-frame callback schedules the sheet; pump a couple of frames so
      // the modal bottom sheet route is fully mounted before the helper runs.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(BottomSheet), findsOneWidget);

      final sw = Stopwatch()..start();
      await e2eCloseBottomSheet(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        sw.elapsed < const Duration(seconds: 2),
        isTrue,
        reason:
            'Pop-once-then-poll must finish well inside the 5s default budget '
            'on a clean dismiss path (Refs GitHub #2336).',
      );
    },
  );

  testWidgets('e2eCloseBottomSheet respects a tight overallTimeout window', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapE2eApp(const CloseBottomSheetHost()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(BottomSheet), findsOneWidget);

    // 1s is enough for the dismiss animation but tests that the helper still
    // works when callers pass a tighter window than the 5s default.
    await e2eCloseBottomSheet(
      tester,
      overallTimeout: const Duration(seconds: 1),
    );
    expect(find.byType(BottomSheet), findsNothing);
  });
}
