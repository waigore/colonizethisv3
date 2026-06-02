import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_chrome.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('TrainDialogHeader', () {
    testWidgets('uses CtNinePatchButton dismiss instead of IconButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrainDialogHeader(
              title: 'Train Civilians',
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      expect(find.text('Train Civilians'), findsOneWidget);

      final Text title = tester.widget(find.text('Train Civilians'));
      expect(title.style?.color, EditorialMonoclePalette.accent);
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

  test('kTrainDialogLockedOpacity is 0.4 per #2866 AC', () {
    expect(kTrainDialogLockedOpacity, 0.4);
  });
}
