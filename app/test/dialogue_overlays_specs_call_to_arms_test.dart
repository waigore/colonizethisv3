/// Pins SPEC/ui/call-to-arms-dialogue-overlay.md (Refs #4606 Slice D).
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogue_overlays_specs_overture_cta_fixtures.dart';
import 'dialogue_overlays_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CallToArmsDialogueOverlay (SPEC/ui/call-to-arms-dialogue-overlay.md)', () {
    Future<void> pumpCta(
      WidgetTester tester, {
      List<CallToArmsPending> pending = dialogueOverlaysTwoCtaPending,
      void Function(List<CallToArmsDecision>)? onDecisions,
    }) async {
      await tester.pumpWidget(
        wrapCallToArmsDialogueOverlay(
          pending: pending,
          onDecisions: onDecisions ?? (_) {},
        ),
      );
      await pumpDialogueOverlaysUntilSettled(tester);
    }

    testWidgets(
      'renders one Join/Refuse row per pending call and resolves names',
      (WidgetTester tester) async {
        await pumpCta(
          tester,
          pending: const [
            CallToArmsPending(
              allyGpId: 'gp_player',
              defenderGpId: 'gp_portugal',
              aggressorGpId: 'gp_spain',
            ),
          ],
        );

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Join'), findsOneWidget);
        expect(find.text('Refuse'), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
        final String prompt = callToArmsPromptPlainText(tester);
        expect(prompt, contains('Portugal'));
        expect(prompt, contains('Spain'));
      },
    );

    testWidgets(
      'tapping Join on every row emits one CallToArmsDecision per pending '
      'with accepted=true (#2867 R25 / AC5 — Submit enables after all decided)',
      (WidgetTester tester) async {
        List<CallToArmsDecision>? captured;
        await pumpCta(tester, onDecisions: (d) => captured = d);

        await tapDialogueOverlayControl(tester, find.text('Join').at(0));
        await tapDialogueOverlayControl(tester, find.text('Join').at(1));
        await tapDialogueOverlayControl(tester, find.text('Submit'));

        expect(captured, isNotNull);
        expect(captured!.length, 2);
        expect(captured![0].defenderGpId, 'gp_portugal');
        expect(captured![0].accepted, isTrue);
        expect(captured![1].defenderGpId, 'gp_spain');
        expect(captured![1].accepted, isTrue);
      },
    );

    testWidgets(
      'tapping Refuse on the first row and Join on the second row before Submit '
      '(#2867 R25 / AC5 — mixed decision)',
      (WidgetTester tester) async {
        List<CallToArmsDecision>? captured;
        await pumpCta(tester, onDecisions: (d) => captured = d);

        await tapDialogueOverlayControl(tester, find.text('Refuse').at(0));
        await tapDialogueOverlayControl(tester, find.text('Join').at(1));
        await tapDialogueOverlayControl(tester, find.text('Submit'));

        expect(captured, isNotNull);
        expect(captured![0].accepted, isFalse);
        expect(captured![1].accepted, isTrue);
      },
    );

    testWidgets(
      'Submit stays disabled and does not invoke onDecisions while any '
      'call-to-arms row is still undecided (#2867 R25 / AC5 negative case)',
      (WidgetTester tester) async {
        List<CallToArmsDecision>? captured;
        await pumpCta(tester, onDecisions: (d) => captured = d);

        await tapDialogueOverlayControl(
          tester,
          find.text('Submit'),
          warnIfMissed: false,
        );
        expect(captured, isNull);

        await tapDialogueOverlayControl(tester, find.text('Refuse').at(0));
        await tapDialogueOverlayControl(
          tester,
          find.text('Submit'),
          warnIfMissed: false,
        );
        expect(
          captured,
          isNull,
          reason:
              'Submit must remain disabled while the second row is still '
              'undecided (#2867 R25).',
        );
      },
    );

    testWidgets(
      'empty pending list still renders Submit and emits empty list',
      (WidgetTester tester) async {
        List<CallToArmsDecision>? captured;
        await pumpCta(
          tester,
          pending: const [],
          onDecisions: (d) => captured = d,
        );

        expect(find.text('Join'), findsNothing);
        expect(find.text('Submit'), findsOneWidget);

        await tapDialogueOverlayControl(tester, find.text('Submit'));
        expect(captured, isNotNull);
        expect(captured, isEmpty);
      },
    );

    testWidgets('unknown gp ids fall back to the raw id in prompt text', (
      WidgetTester tester,
    ) async {
      await pumpCta(
        tester,
        pending: const [
          CallToArmsPending(
            allyGpId: 'gp_player',
            defenderGpId: 'gp_unknown_defender',
            aggressorGpId: 'gp_unknown_aggressor',
          ),
        ],
      );

      final String prompt = callToArmsPromptPlainText(tester);
      expect(prompt, contains('gp_unknown_defender'));
      expect(prompt, contains('gp_unknown_aggressor'));
    });
  });
}
