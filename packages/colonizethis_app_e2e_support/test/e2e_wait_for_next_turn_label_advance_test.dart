/// Pins the **pre-pump short-circuit** and **`TurnResolutionProcessingDialog`
/// race-gate** contracts of `e2eWaitForNextTurnLabelAdvance` (Refs GitHub
/// #2336 AC2 / AC5).
///
/// Remaining pins live in
/// `support/e2e_wait_for_next_turn_label_advance_guard_group.dart`
/// (#4598 Slice C).
library;

import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/e2e_wait_for_next_turn_label_advance_guard_group.dart';
import 'support/next_turn_label_harness.dart';

Future<void> _pumpHost(
  WidgetTester tester,
  NextTurnLabelController controller, {
  Duration? flipAfter,
  String? flipToLabel,
  bool? flipToShowDialog,
}) => pumpNextTurnLabelHost(
  tester,
  controller,
  flipAfter: flipAfter,
  flipToLabel: flipToLabel,
  flipToShowDialog: flipToShowDialog,
);

void main() {
  suppressLogsForTests();

  testWidgets(
    'returns immediately when current label already differs from before',
    (WidgetTester tester) async {
      final controller = NextTurnLabelController(
        initialLabel: 'Next turn (2 / 1492)',
      );
      await _pumpHost(tester, controller);
      final sw = Stopwatch()..start();
      final elapsed = await e2eWaitForNextTurnLabelAdvance(
        tester,
        turnLabelBefore: 'Next turn (1 / 1492)',
        timeout: const Duration(seconds: 5),
      );
      expect(
        elapsed,
        lessThan(const Duration(milliseconds: 100)),
        reason:
            'Pre-pump short-circuit must return ~Duration.zero when the label '
            'already changed before the helper started polling (#2336 AC5).',
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 200)),
        reason:
            'Wall-clock for the pre-pump short-circuit path must stay well '
            'under the timeout cap; large drift signals a regression in the '
            'condition-before-first-pump contract.',
      );
    },
  );

  testWidgets('returns once a scheduled label flip lands during pump', (
    WidgetTester tester,
  ) async {
    final controller = NextTurnLabelController(
      initialLabel: 'Next turn (1 / 1492)',
    );
    await _pumpHost(
      tester,
      controller,
      flipAfter: const Duration(milliseconds: 80),
      flipToLabel: 'Next turn (2 / 1492)',
    );

    final returned = await e2eWaitForNextTurnLabelAdvance(
      tester,
      turnLabelBefore: 'Next turn (1 / 1492)',
      timeout: const Duration(seconds: 5),
    );

    expect(
      controller.label,
      'Next turn (2 / 1492)',
      reason:
          'Sanity check: the scheduled flip must have landed before the '
          'helper returned, otherwise the helper short-circuited on a '
          'stale label.',
    );
    expect(
      returned,
      lessThan(const Duration(seconds: 5)),
      reason:
          'Helper must complete strictly within its timeout when the label '
          'change is observed; reaching the timeout would indicate the '
          'adaptive backoff missed the flip.',
    );
  });

  testWidgets(
    'fails with TestFailure when label never advances within timeout',
    (WidgetTester tester) async {
      final controller = NextTurnLabelController(
        initialLabel: 'Next turn (1 / 1492)',
      );
      await _pumpHost(tester, controller);
      Object? caught;
      try {
        await e2eWaitForNextTurnLabelAdvance(
          tester,
          turnLabelBefore: 'Next turn (1 / 1492)',
          timeout: const Duration(milliseconds: 200),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent identical label must hit the timeout failure path so '
            'real regressions are not silently swallowed (#2336 AC10).',
      );
    },
  );

  testWidgets(
    'holds return until TurnResolutionProcessingDialog clears even if label already differs',
    (WidgetTester tester) async {
      final controller = NextTurnLabelController(
        initialLabel: 'Next turn (2 / 1492)',
        initialShowProcessingDialog: true,
      );
      await _pumpHost(
        tester,
        controller,
        flipAfter: const Duration(milliseconds: 250),
        flipToShowDialog: false,
      );
      expect(find.byType(TurnResolutionProcessingDialog), findsOneWidget);

      final returned = await e2eWaitForNextTurnLabelAdvance(
        tester,
        turnLabelBefore: 'Next turn (1 / 1492)',
        timeout: const Duration(seconds: 5),
      );

      expect(
        find.byType(TurnResolutionProcessingDialog),
        findsNothing,
        reason:
            'Dialog must have cleared by the time the helper returned — '
            'otherwise the dialog-gate race was lost.',
      );
      expect(
        controller.showProcessingDialog,
        isFalse,
        reason:
            'Sanity check: the scheduled flip must have run before the '
            'helper returned.',
      );
      expect(
        returned,
        lessThan(const Duration(seconds: 5)),
        reason:
            'Once the processing dialog clears, the helper must observe the '
            'already-different label on the next adaptive poll step and '
            'return within the 5s budget.',
      );
    },
  );

  registerWaitForNextTurnLabelAdvanceGuardGroup();
}
