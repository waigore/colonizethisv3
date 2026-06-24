import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_chrome.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('TrainDialogHeader', () {
    testWidgets(
      'renders a centered accent title with no × dismiss button '
      '(#3568 chrome parity)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TrainDialogHeader(title: 'Train Civilians'),
            ),
          ),
        );

        // No dismiss control of any kind — dialog closes via scrim / back.
        expect(find.byType(IconButton), findsNothing);
        expect(find.byType(CtNinePatchButton), findsNothing);
        expect(find.text('×'), findsNothing);

        expect(find.text('Train Civilians'), findsOneWidget);
        final Text title = tester.widget(find.text('Train Civilians'));
        expect(title.style?.color, EditorialMonoclePalette.accent);
        expect(title.textAlign, TextAlign.center);
      },
    );
  });

  group('TrainDialogUnitNameLine', () {
    testWidgets('locked rows prefix the name with the 🔒 glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrainDialogUnitNameLine(
              name: kUnitTypeMerchant,
              isLocked: true,
            ),
          ),
        ),
      );

      expect(
        find.text('$kTrainDialogLockPrefix$kUnitTypeMerchant'),
        findsOneWidget,
      );
      expect(find.text(kUnitTypeMerchant), findsNothing);
    });

    testWidgets('unlocked rows render the bare name with no 🔒 prefix', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrainDialogUnitNameLine(
              name: kUnitTypeBuilder,
              isLocked: false,
            ),
          ),
        ),
      );

      expect(find.text(kUnitTypeBuilder), findsOneWidget);
      expect(find.textContaining('\u{1F512}'), findsNothing);
    });
  });

  group('TrainDialogSectionDivider', () {
    testWidgets('renders CtBrassDivider', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TrainDialogSectionDivider()),
        ),
      );
      expect(find.byType(CtBrassDivider), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });
  });

  group('TrainDialogResourceBar', () {
    testWidgets(
      'renders entries inside a boxed inset strip with no danger when '
      'deficitHint is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TrainDialogResourceBar(
                entries: [
                  TrainDialogResourceEntry(label: 'Treasury:', value: '£5,000'),
                  TrainDialogResourceEntry(label: 'Paper:', value: '12'),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(TrainDialogResourceBarBox), findsOneWidget);
        expect(find.textContaining('Treasury:'), findsOneWidget);
        expect(find.textContaining('£5,000'), findsOneWidget);
        expect(find.textContaining('Paper:'), findsOneWidget);
        // No deficit row when deficitHint is null.
        expect(find.textContaining('low'), findsNothing);
      },
    );

    testWidgets('renders deficitHint below the box in the danger colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrainDialogResourceBar(
              entries: [
                TrainDialogResourceEntry(label: 'Treasury:', value: '£0'),
              ],
              deficitHint: 'Treasury low',
            ),
          ),
        ),
      );

      final Text hint = tester.widget(find.text('Treasury low'));
      expect(hint.style?.color, EditorialMonoclePalette.danger);
    });
  });

  test('kTrainDialogLockedOpacity is 0.5 per #3568 mockup parity', () {
    expect(kTrainDialogLockedOpacity, 0.5);
  });
}
