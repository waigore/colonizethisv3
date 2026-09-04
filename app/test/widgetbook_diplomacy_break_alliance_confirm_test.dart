// Widget test pin for Diplomacy Panel → Break Alliance confirm
// Widgetbook use case (Refs #4719).
//
// Pins SPEC/ui/diplomacy-panel.md § Widgetbook and the AC
// "Break Alliance confirm Widgetbook":
//  1. The use case is wired into diplomacyPanelDirectories.
//  2. The builder pumps without exceptions and shows the rest-of-turn
//     lock copy toward Spain without claiming Boycott is blocked.

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

  group('Diplomacy Panel Widgetbook Break Alliance confirm (Refs #4719)', () {
    testWidgets('use case is wired into diplomacyPanelDirectories under the '
        'canonical folder + name', (WidgetTester tester) async {
      final useCase = findWidgetbookUseCase(
        diplomacyPanelDirectories,
        folderName: 'Diplomacy Panel',
        useCaseName: 'Break Alliance confirm — rest-of-turn lock',
      );
      expect(useCase.builder, isNotNull);
    });

    testWidgets(
      'builder pumps lock Effect lines toward Spain and omits Boycott',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: 'Diplomacy Panel',
          useCaseName: 'Break Alliance confirm — rest-of-turn lock',
        );

        await pumpWidgetbookUseCaseAtSize(tester, useCase);

        expect(tester.takeException(), isNull);
        expect(find.byType(CtConfirmDialog), findsOneWidget);
        expect(find.text('Break Alliance'), findsOneWidget);
        expect(find.textContaining('Until next turn'), findsOneWidget);
        expect(find.textContaining('Spain'), findsWidgets);
        expect(find.textContaining('Favored Trading Partner'), findsOneWidget);
        expect(find.textContaining('Grant Aid'), findsOneWidget);
        expect(find.textContaining('Set Subsidy'), findsOneWidget);
        expect(find.textContaining('Declare War'), findsOneWidget);
        expect(find.textContaining('Offer Peace'), findsOneWidget);
        expect(find.textContaining('lock clears next turn'), findsOneWidget);
        expect(find.textContaining('Boycott'), findsNothing);
      },
    );
  });
}
