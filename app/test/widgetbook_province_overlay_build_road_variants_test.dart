// Widget test pin for `Province Overlay` Build road inline-action variants.
// Refs #4260 — document-app-ui MAP20001 Tile Build road behavior/variants.

import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:widgetbook_host/catalogs/catalog.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  const folderName = 'Province Overlay';

  group('Province Overlay Build road Widgetbook variants (Refs #4260)', () {
    for (final useCaseName in [
      'Standalone — tile Build road enabled',
      'Standalone — tile Build road disabled',
      'Standalone — tile Build road hidden',
    ]) {
      testWidgets('$useCaseName is wired into provinceOverlayDirectories', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: useCaseName,
        );
        expect(useCase.builder, isNotNull);
      });
    }

    testWidgets(
      'enabled story shows an enabled Build road inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Build road enabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtIconAction>(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.add_road,
          ),
        );
        expect(action.enabled, isTrue);
      },
    );

    testWidgets(
      'disabled story shows a disabled Build road inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Build road disabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtIconAction>(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.add_road,
          ),
        );
        expect(action.enabled, isFalse);
      },
    );

    testWidgets(
      'hidden story omits the Build road inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Build road hidden',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.add_road,
          ),
          findsNothing,
        );
      },
    );
  });
}
