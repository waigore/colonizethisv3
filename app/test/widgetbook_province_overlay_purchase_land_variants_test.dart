// Widget test pin for `Province Overlay` Purchase land inline-action variants.
// Refs #4274 — document-app-ui MAP20001 Tile Purchase land behavior/variants.

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

  group('Province Overlay Purchase land Widgetbook variants (Refs #4274)', () {
    for (final useCaseName in [
      'Standalone — tile Purchase land enabled',
      'Standalone — tile Purchase land disabled',
      'Standalone — tile Purchase land hidden',
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
      'enabled story shows an enabled Purchase land inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Purchase land enabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtIconAction>(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.payments,
          ),
        );
        expect(action.enabled, isTrue);
      },
    );

    testWidgets(
      'disabled story shows a disabled Purchase land inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Purchase land disabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtIconAction>(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.payments,
          ),
        );
        expect(action.enabled, isFalse);
      },
    );

    testWidgets(
      'hidden story omits the Purchase land inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Purchase land hidden',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.payments,
          ),
          findsNothing,
        );
      },
    );
  });
}
