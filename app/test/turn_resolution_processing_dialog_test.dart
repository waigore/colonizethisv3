// Turn-resolution processing modal (#2160).

import 'package:colonizethis_app/features/game/flame/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_progress_labels.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('TurnResolutionProcessingDialog shows title and phase text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: TurnResolutionProcessingDialog(
            phaseText: 'Validating orders...',
          ),
        ),
      ),
    );

    expect(find.text('Processing Turn'), findsOneWidget);
    expect(find.text('Validating orders...'), findsOneWidget);
    final pop = tester.widget<PopScope>(find.byType(PopScope));
    expect(pop.canPop, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'awaitTurnResolutionProcessingDialogFirstPaint completes after a frame',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      final done = awaitTurnResolutionProcessingDialogFirstPaint();
      await tester.pump();
      await done;
    },
  );
}
