// Widget test pin for Diplomacy Panel → Join Empire confirm
// Widgetbook use cases (Refs #4729).

import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widget_test_assets.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpNinePatchAssets);

  group('Diplomacy Panel Widgetbook Join Empire confirm (Refs #4729)', () {
    testWidgets('Minor absorb use case is wired and pumps absorption copy', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        diplomacyPanelDirectories,
        folderName: 'Diplomacy Panel',
        useCaseName: 'Join Empire confirm — Minor absorb',
      );
      await pumpWidgetbookUseCaseAtSize(tester, useCase);
      expect(tester.takeException(), isNull);
      expect(find.byType(CtConfirmDialog), findsOneWidget);
      expect(find.text('Join Empire'), findsOneWidget);
      expect(find.textContaining('absorbed'), findsOneWidget);
      expect(find.textContaining('leave the map'), findsOneWidget);
      expect(find.textContaining('Bavaria'), findsWidgets);
    });

    testWidgets('Tribe colony use case pumps colony copy without absorbed', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        diplomacyPanelDirectories,
        folderName: 'Diplomacy Panel',
        useCaseName: 'Join Empire confirm — Tribe colony',
      );
      await pumpWidgetbookUseCaseAtSize(tester, useCase);
      expect(tester.takeException(), isNull);
      expect(find.byType(CtConfirmDialog), findsOneWidget);
      expect(find.textContaining('colony'), findsOneWidget);
      expect(find.textContaining('31 Old World provinces'), findsOneWidget);
      expect(find.textContaining('absorbed'), findsNothing);
    });

    testWidgets('GP absorb use case pumps no-treasury absorption copy', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        diplomacyPanelDirectories,
        folderName: 'Diplomacy Panel',
        useCaseName: 'Join Empire confirm — GP absorb',
      );
      await pumpWidgetbookUseCaseAtSize(tester, useCase);
      expect(tester.takeException(), isNull);
      expect(find.byType(CtConfirmDialog), findsOneWidget);
      expect(find.textContaining('nearly defeated'), findsOneWidget);
      expect(find.textContaining('absorbed'), findsOneWidget);
      expect(find.textContaining('No treasury charge'), findsOneWidget);
    });
  });
}
