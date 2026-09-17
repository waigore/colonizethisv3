// Widget test pin for `Player Turn Event Feed Card` → `Work complete —
// payoff variants` under widgetbook_host/lib/catalogs/catalog_event_feed.dart.
//
// Pins past-tense payoff copy (Refs #4778) so renaming or removing the story
// surfaces in CI.

import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Player Turn Event Feed Card Widgetbook work-complete payoff (Refs #4778)',
    () {
      testWidgets('Work complete payoff story is wired into '
          'playerTurnEventFeedCardDirectories', (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          playerTurnEventFeedCardDirectories,
          folderName: 'Player Turn Event Feed Card',
          useCaseName: 'Work complete — payoff variants',
        );
        expect(useCase.builder, isNotNull);
      });

      testWidgets('Work complete builder pumps payoff copy', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          playerTurnEventFeedCardDirectories,
          folderName: 'Player Turn Event Feed Card',
          useCaseName: 'Work complete — payoff variants',
        );

        await pumpWidgetbookUseCaseAtSize(tester, useCase);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
        expect(
          find.textContaining('This province is now fully visible'),
          findsOneWidget,
        );
        expect(find.textContaining('Grain'), findsWidgets);
        expect(
          find.textContaining('Town workshops pause until level 4'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.chevron_right), findsWidgets);
      });
    },
  );
}
