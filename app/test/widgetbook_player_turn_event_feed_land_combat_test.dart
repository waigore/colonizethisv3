// Widget test pin for `Player Turn Event Feed Card` → `Land combat — outcome
// variants (Refs #4548)` under widgetbook_host/lib/catalogs/catalog_event_feed.dart.
//
// Pins the four handbook land-battle outcome rows (attacker victory, defender
// holds, stalemate, mutual wipe) so renaming or removing the story surfaces in
// CI before reviewers lose the #4548 combat-copy contract.

import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Player Turn Event Feed Card Widgetbook land-combat story (Refs #4548)',
    () {
      testWidgets(
        'Land combat outcome variants is wired into '
        'playerTurnEventFeedCardDirectories',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Land combat — outcome variants (Refs #4548)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Land combat outcome variants builder pumps all four handbook rows',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Land combat — outcome variants (Refs #4548)',
          );

          await pumpWidgetbookUseCaseAtSize(tester, useCase);
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
          for (final label in [
            'Attacker victory',
            'Defender holds',
            'Stalemate',
            'Both armies destroyed',
          ]) {
            expect(
              find.textContaining(label, skipOffstage: false),
              findsOneWidget,
            );
          }
        },
      );
    },
  );
}
