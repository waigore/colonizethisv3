// Widget test pin for Turn news **Your court** Widgetbook variants (Refs #4532).
//
// SPEC: SPEC/ui/turn-news-dialog.md § Widgetbook / Your court block.

import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  const folderName = 'Turn news';

  group('Turn news court Widgetbook variants (Refs #4532)', () {
    for (final useCaseName in [
      'Empty digest + court',
      'Gazette + court',
      'Court + spy footer',
    ]) {
      testWidgets('$useCaseName is wired into turnNewsDialogDirectories', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          turnNewsDialogDirectories,
          folderName: folderName,
          useCaseName: useCaseName,
        );
        expect(useCase.builder, isNotNull);
      });
    }

    testWidgets('Empty digest + court story shows court block without empty copy', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        turnNewsDialogDirectories,
        folderName: folderName,
        useCaseName: 'Empty digest + court',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.textContaining('Your court:'), findsOneWidget);
      expect(find.text('No major events last turn.'), findsNothing);
      expect(find.byType(TurnNewsDialog), findsOneWidget);
    });

    testWidgets('Court + spy footer story shows both footers', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        turnNewsDialogDirectories,
        folderName: folderName,
        useCaseName: 'Court + spy footer',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.textContaining('Your court:'), findsOneWidget);
      expect(find.textContaining('Your spies report'), findsOneWidget);
    });
  });
}
