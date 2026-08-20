// Widget test pin for `Player Turn Event Feed Card` → `Naval combat — outcome
// variants (Refs #4558)` under widgetbook_host/lib/catalogs/catalog_event_feed.dart.
//
// Pins the four handbook naval-battle outcome rows so renaming or removing the
// story surfaces in CI before reviewers lose the #4558 combat-copy contract.

import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Player Turn Event Feed Card Widgetbook naval-combat story (Refs #4558)',
    () {
      testWidgets(
        'Naval combat outcome variants is wired into '
        'playerTurnEventFeedCardDirectories',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Naval combat — outcome variants (Refs #4558)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Naval combat outcome variants builder pumps all four handbook rows',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: 'Naval combat — outcome variants (Refs #4558)',
          );

          await pumpWidgetbookUseCaseAtSize(tester, useCase);
          await tester.pumpAndSettle(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          expect(find.byKey(PlayerTurnEventFeedCard.surfaceKey), findsOneWidget);
          for (final label in [
            'Attacker victory',
            'Defender holds',
            'Stalemate',
            'Both fleets destroyed',
          ]) {
            expect(
              find.textContaining(label, skipOffstage: false),
              findsOneWidget,
            );
          }
          expect(
            find.textContaining('retreated', skipOffstage: false),
            findsOneWidget,
          );
        },
      );
    },
  );
}
