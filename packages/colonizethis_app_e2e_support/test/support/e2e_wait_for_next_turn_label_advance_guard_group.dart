// Extracted from e2e_wait_for_next_turn_label_advance_test.dart (#4598 Slice C).
library;

import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'e2e_widget_pump_harness.dart';
import 'next_turn_label_harness.dart';

Future<void> _pumpLabelHost(
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

void registerWaitForNextTurnLabelAdvanceGuardGroup() {
  group('post-pump final check (timeout-edge correctness)', () {
    testWidgets(
      'returns elapsed via post-loop final check when the while loop is '
      'skipped (Duration.zero) and the label already differs',
      (WidgetTester tester) async {
        final controller = NextTurnLabelController(
          initialLabel: 'Next turn (2 / 1492)',
        );
        await _pumpLabelHost(tester, controller);

        final returned = await e2eWaitForNextTurnLabelAdvance(
          tester,
          turnLabelBefore: 'Next turn (1 / 1492)',
          timeout: Duration.zero,
        );

        expect(
          returned,
          lessThan(const Duration(milliseconds: 100)),
          reason:
              'Post-loop final check must report ~Duration.zero — only the '
              'final check ran, the pump loop was skipped.',
        );
      },
    );

    testWidgets(
      'still fails with TestFailure when the label never advances and '
      'the loop is skipped (Duration.zero, additive contract)',
      (WidgetTester tester) async {
        final controller = NextTurnLabelController(
          initialLabel: 'Next turn (1 / 1492)',
        );
        await _pumpLabelHost(tester, controller);

        Object? caught;
        try {
          await e2eWaitForNextTurnLabelAdvance(
            tester,
            turnLabelBefore: 'Next turn (1 / 1492)',
            timeout: Duration.zero,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'The post-loop final check is additive — when the label '
              'stays equal through both the (skipped) loop and the '
              'post-loop check, the helper must still hit the timeout '
              '`fail()` path so the absence is attributable in CI logs '
              '(Refs GitHub #2336 AC10).',
        );
        expect(
          caught.toString(),
          contains('did not advance'),
          reason:
              'Failure message must call out the missed label advance so '
              'the helper failure is attributable in CI logs.',
        );
      },
    );

    testWidgets('post-loop final check refuses to return while the '
        'TurnResolutionProcessingDialog is still mounted', (
      WidgetTester tester,
    ) async {
      final controller = NextTurnLabelController(
        initialLabel: 'Next turn (2 / 1492)',
        initialShowProcessingDialog: true,
      );
      await _pumpLabelHost(tester, controller);
      expect(find.byType(TurnResolutionProcessingDialog), findsOneWidget);

      Object? caught;
      try {
        await e2eWaitForNextTurnLabelAdvance(
          tester,
          turnLabelBefore: 'Next turn (1 / 1492)',
          timeout: Duration.zero,
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Even though the post-loop final check sees a different '
            'label, it must observe `sawProcessingDialog=true` AND a '
            'still-mounted dialog and therefore refuse to return — '
            'matching the in-loop dialog gate so the post-loop fix '
            'does not weaken the race contract pinned by the '
            'sibling "holds return until …" test (#2336 AC5).',
      );
    });
  });

  testWidgets(
    'e2eReadNextTurnButtonLabel returns null when no next-turn button is mounted',
    (WidgetTester tester) async {
      await pumpE2eEmptyScaffold(tester);
      expect(e2eReadNextTurnButtonLabel(tester), isNull);
    },
  );

  testWidgets(
    'e2eReadNextTurnButtonLabel returns null when subtree has more than one Text',
    (WidgetTester tester) async {
      await pumpE2eScaffold(
        tester,
        Center(
          child: TextButton(
            key: kGameMapNextTurnButtonKey,
            onPressed: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next turn'),
                SizedBox(width: 4),
                Text('(1 / 1492)'),
              ],
            ),
          ),
        ),
      );
      expect(
        e2eReadNextTurnButtonLabel(tester),
        isNull,
        reason:
            'Two-text layout breaks the single-Text contract; helper must '
            'return null so callers fall back to other readiness signals '
            '(`SPEC/program/e2e-integration-tests.md`).',
      );
    },
  );
}
