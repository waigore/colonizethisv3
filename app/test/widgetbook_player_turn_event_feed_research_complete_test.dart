// Widget test pin for `Player Turn Event Feed Card` → `Research complete —
// tappable link to Technology` under
// widgetbook_host/lib/catalogs/catalog_event_feed.dart.
//
// Pins name + effect-clause copy (Refs #4724) so renaming or removing the
// story surfaces in CI.

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
    'Player Turn Event Feed Card Widgetbook research-complete story '
    '(Refs #4724)',
    () {
      testWidgets(
        'Research complete story is wired into '
        'playerTurnEventFeedCardDirectories',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Research complete — tappable link to Technology',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Research complete builder pumps name and effect clause',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Research complete — tappable link to Technology',
          );

          await pumpWidgetbookUseCaseAtSize(tester, useCase);
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
          expect(find.textContaining('Crop Rotation'), findsOneWidget);
          expect(find.textContaining('Sheep Ranching'), findsOneWidget);
          expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        },
      );
    },
  );
}
