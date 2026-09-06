import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'overture_dialogue_overlay_test_support.dart';

void main() {
  suppressLogsForTests();

  group('OvertureDialogueOverlay', () {
    testWidgets(
      'skipIntroForTest: Accept first + Reject second + Submit yields decisions in order (#2867 R23 / AC4)',
      (WidgetTester tester) async {
        List<OvertureDecision>? submitted;

        await pumpOvertureOverlay(
          tester,
          offers: twoStageGp2OvertureOffers,
          onDecisions: (d) => submitted = List.of(d),
        );

        expect(find.text('Diplomatic overtures'), findsOneWidget);
        expect(find.text('Great Power 2'), findsNWidgets(2));
        expect(find.text('trade consulate'), findsOneWidget);
        expect(find.text('embassy'), findsOneWidget);
        expect(find.text(': '), findsNWidgets(2));

        await tester.tap(find.text('Submit'), warnIfMissed: false);
        await tester.pump();
        expect(submitted, isNull);

        await tester.tap(find.text('Accept').first);
        await tester.pump();
        await tester.tap(find.text('Reject').last);
        await tester.pump();

        await tester.tap(find.text('Submit'));
        await tester.pump();

        expect(submitted, isNotNull);
        expect(submitted, hasLength(2));
        expect(submitted![0].accepted, isTrue);
        expect(submitted![1].accepted, isFalse);
        expect(submitted![0].stage, OvertureStage.tradeConsulate);
        expect(submitted![1].stage, OvertureStage.embassy);
      },
    );

    testWidgets(
      'phase 2 Submit is disabled until every row has a non-null decision '
      '(#2867 R23 / AC4 — positive enable transition)',
      (WidgetTester tester) async {
        await pumpOvertureOverlay(tester, offers: twoStageGp2OvertureOffers);

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('overtureSubmitButton'),
        );
        expect(submitFinder, findsOneWidget);

        CtNinePatchButton submitButton() =>
            tester.widget<CtNinePatchButton>(submitFinder);

        expect(submitButton().enabled, isFalse);

        await tester.tap(find.text('Accept').first);
        await tester.pump();
        expect(submitButton().enabled, isFalse);

        await tester.tap(find.text('Reject').last);
        await tester.pump();
        expect(submitButton().enabled, isTrue);
      },
    );

    testWidgets('phase 2 Submit disabled while only the second row is decided '
        '(#2867 R23 / AC4 — negative case)', (WidgetTester tester) async {
      List<OvertureDecision>? submitted;

      await pumpOvertureOverlay(
        tester,
        offers: twoStageGp2OvertureOffers,
        onDecisions: (d) => submitted = List.of(d),
      );

      await tester.tap(find.text('Reject').last);
      await tester.pump();

      final Finder submitFinder = find.byKey(
        const ValueKey<String>('overtureSubmitButton'),
      );
      final CtNinePatchButton submitButton = tester.widget<CtNinePatchButton>(
        submitFinder,
      );
      expect(submitButton.enabled, isFalse);

      await tester.tap(find.text('Submit'), warnIfMissed: false);
      await tester.pump();
      expect(submitted, isNull);
    });
  });
}
