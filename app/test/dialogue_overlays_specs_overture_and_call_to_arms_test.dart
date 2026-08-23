/// Pins SPEC/ui contracts for OvertureDialogueOverlay.
///
/// Call-to-arms cases live in
/// `dialogue_overlays_specs_call_to_arms_test.dart` (Refs #4606 Slice D).
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogue_overlays_specs_overture_cta_fixtures.dart';
import 'dialogue_overlays_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('OvertureDialogueOverlay (SPEC/ui/overture-dialogue-overlay.md)', () {
    Future<void> pumpOverture(
      WidgetTester tester, {
      List<OvertureOffer> offers = dialogueOverlaysTwoOvertureOffers,
      void Function(List<OvertureDecision>)? onDecisions,
    }) async {
      await tester.pumpWidget(
        wrapOvertureDialogueOverlay(
          offers: offers,
          onDecisions: onDecisions ?? (_) {},
        ),
      );
      await pumpDialogueOverlaysUntilSettled(tester);
    }

    testWidgets(
      'phase 2 renders one Accept/Reject row per pending overture and Submit',
      (WidgetTester tester) async {
        await pumpOverture(tester);
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Accept'), findsNWidgets(2));
        expect(find.text('Reject'), findsNWidgets(2));
        expect(find.text('Submit'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Accept on every row emits one OvertureDecision per offer with accepted=true '
      '(#2867 R23 / AC4 — Submit enables after all decided)',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        await pumpOverture(tester, onDecisions: (d) => captured = d);

        await tapDialogueOverlayControl(tester, find.text('Accept').at(0));
        await tapDialogueOverlayControl(tester, find.text('Accept').at(1));
        await tapDialogueOverlayControl(tester, find.text('Submit'));

        expect(captured, isNotNull);
        expect(captured!.length, 2);
        expect(captured![0].offererGpId, 'gp_spain');
        expect(captured![0].stage, OvertureStage.tradeConsulate);
        expect(captured![0].accepted, isTrue);
        expect(captured![1].offererGpId, 'gp_portugal');
        expect(captured![1].stage, OvertureStage.embassy);
        expect(captured![1].accepted, isTrue);
      },
    );

    testWidgets(
      'tapping Accept on the first row and Reject on the second row before Submit '
      '(#2867 R23 / AC4 — mixed decision)',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        await pumpOverture(tester, onDecisions: (d) => captured = d);

        await tapDialogueOverlayControl(tester, find.text('Accept').at(0));
        await tapDialogueOverlayControl(tester, find.text('Reject').at(1));
        await tapDialogueOverlayControl(tester, find.text('Submit'));

        expect(captured, isNotNull);
        expect(captured!.length, 2);
        expect(captured![0].accepted, isTrue);
        expect(captured![1].accepted, isFalse);
        expect(captured![1].offererGpId, 'gp_portugal');
      },
    );

    testWidgets(
      'Submit stays disabled and does not invoke onDecisions while any '
      'overture row is still undecided (#2867 R23 / AC4 negative case)',
      (WidgetTester tester) async {
        List<OvertureDecision>? captured;
        await pumpOverture(tester, onDecisions: (d) => captured = d);

        await tapDialogueOverlayControl(
          tester,
          find.text('Submit'),
          warnIfMissed: false,
        );
        expect(captured, isNull);

        await tapDialogueOverlayControl(tester, find.text('Accept').at(0));
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
              'undecided (#2867 R23).',
        );
      },
    );

    testWidgets('empty offer list still renders Submit and emits empty list', (
      WidgetTester tester,
    ) async {
      List<OvertureDecision>? captured;
      await pumpOverture(
        tester,
        offers: const [],
        onDecisions: (d) => captured = d,
      );

      expect(find.text('Accept'), findsNothing);
      expect(find.text('Submit'), findsOneWidget);

      await tapDialogueOverlayControl(tester, find.text('Submit'));
      expect(captured, isNotNull);
      expect(captured, isEmpty);
    });
  });
}
