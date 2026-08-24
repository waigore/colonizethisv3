// 320 dp pins for turn-resolution processing and combat-mode choice (Refs #4352).

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void registerDialogs320ProcessingAndCombatTests() {
  group('SPEC/ui/mobile-adaptation.md § 7 — TurnResolutionProcessingDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    const String phaseText = 'Resolving turn 3...';

    testWidgets('AC (positive) TurnResolutionProcessingDialog @ 320×640: no '
        'RenderFlex overflow exception, title + phase text render '
        '(the CtLoadingIndicator + 10 dp gap + Expanded phase-text row must '
        'fit within the ~288 dp CtDialogShell content column)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        const TurnResolutionProcessingDialog(phaseText: phaseText),
        size: kDialogs320MinViewport,
        settle: false,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: '
            'TurnResolutionProcessingDialog must not emit a RenderFlex '
            'overflow exception at kMinViewportWidth (320 dp). The '
            'CtLoadingIndicator + Expanded(phase text) row from '
            'SPEC/program/turn-resolution.md (Processing-turn modal) must '
            'wrap within the ~288 dp CtDialogShell content column.',
      );
      expect(find.text('Processing Turn'), findsOneWidget);
      expect(find.text(phaseText), findsOneWidget);
    });

    testWidgets('Negative control: TurnResolutionProcessingDialog @ '
        '1024×768 also pumps without exception (regression sentinel for '
        'the overflow contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        const TurnResolutionProcessingDialog(phaseText: phaseText),
        size: kDialogs320WideRegressionViewport,
        settle: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Processing Turn'), findsOneWidget);
      expect(find.text(phaseText), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — CombatModeChoiceDialog @ 320 dp '
      '(Refs #2870 S8/S10)', () {
    const String provinceName = 'Lisbon';

    testWidgets(
      'AC (positive) CombatModeChoiceDialog (regular province) @ 320×640: '
      'no RenderFlex overflow exception, title + both action labels render '
      '(the end-aligned Auto-Resolve + 8 dp gap + Quick Battle row must fit '
      'within the ~288 dp CtDialogShell content column)',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: provinceName,
            isCapitalSiege: false,
          ),
          size: kDialogs320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: CombatModeChoiceDialog '
              '(regular province) must not emit a RenderFlex overflow '
              'exception at kMinViewportWidth (320 dp). The title + muted '
              'body + end-aligned Auto-Resolve / Quick Battle '
              'CtNinePatchButton row from '
              'SPEC/ui/combat-mode-choice-dialog.md must wrap within the '
              '~288 dp CtDialogShell content column.',
        );
        expect(find.textContaining(provinceName), findsOneWidget);
        expect(find.textContaining('Auto-Resolve'), findsOneWidget);
        expect(find.textContaining('Quick Battle'), findsOneWidget);
      },
    );

    testWidgets('Negative control: CombatModeChoiceDialog (regular province) '
        '@ 1024×768 also pumps without exception (regression sentinel for '
        'the overflow contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: provinceName,
          isCapitalSiege: false,
        ),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining(provinceName), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsOneWidget);
      expect(find.textContaining('Quick Battle'), findsOneWidget);
    });

    testWidgets(
      'AC (positive) CombatModeChoiceDialog (capital siege) @ 320×640: '
      'no RenderFlex overflow exception, title + Quick Battle action render '
      '(Auto-Resolve is hidden; the single end-aligned Quick Battle button '
      'must fit within the ~288 dp CtDialogShell content column)',
      (WidgetTester tester) async {
        await pumpDialogs320At(
          tester,
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Madrid',
            isCapitalSiege: true,
          ),
          size: kDialogs320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: CombatModeChoiceDialog '
              '(capital siege) must not emit a RenderFlex overflow '
              'exception at kMinViewportWidth (320 dp). The forced '
              'Quick Battle-only action row from '
              'SPEC/ui/combat-mode-choice-dialog.md must wrap within the '
              '~288 dp CtDialogShell content column.',
        );
        expect(find.textContaining('Madrid'), findsOneWidget);
        expect(find.textContaining('Auto-Resolve'), findsNothing);
        expect(find.textContaining('Quick Battle'), findsWidgets);
      },
    );

    testWidgets('Negative control: CombatModeChoiceDialog (capital siege) @ '
        '1024×768 also pumps without exception (regression sentinel for the '
        'overflow contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pumpDialogs320At(
        tester,
        CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: 'Madrid',
          isCapitalSiege: true,
        ),
        size: kDialogs320WideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Madrid'), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsNothing);
      expect(find.textContaining('Quick Battle'), findsWidgets);
    });
  });
}
