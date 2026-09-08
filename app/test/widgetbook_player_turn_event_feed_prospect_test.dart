// Widget test pin for `Player Turn Event Feed Card` → `Prospect complete —
// found / none` under widgetbook_host/lib/catalogs/catalog_event_feed.dart.
//
// Pins survey-result copy (Refs #4746) so renaming or removing the story
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
    'Player Turn Event Feed Card Widgetbook Prospect story (Refs #4746)',
    () {
      testWidgets('Prospect complete story is wired into '
          'playerTurnEventFeedCardDirectories', (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          playerTurnEventFeedCardDirectories,
          folderName: 'Player Turn Event Feed Card',
          useCaseName: 'Prospect complete — found / none',
        );
        expect(useCase.builder, isNotNull);
      });

      testWidgets('Prospect builder pumps found and none copy', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          playerTurnEventFeedCardDirectories,
          folderName: 'Player Turn Event Feed Card',
          useCaseName: 'Prospect complete — found / none',
        );

        await pumpWidgetbookUseCaseAtSize(tester, useCase);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
        expect(find.textContaining('Prospect found Iron'), findsOneWidget);
        expect(
          find.textContaining('Prospect found no mineral'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.chevron_right), findsWidgets);
      });
    },
  );
}
