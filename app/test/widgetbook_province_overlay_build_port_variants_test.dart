// Widget test pin for `Province Overlay` Build port inline-action variants.
// Refs #4332 — document-app-ui MAP20001 Tile Build port behavior/variants.

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

  group('Province Overlay Build port Widgetbook variants (Refs #4332)', () {
    for (final useCaseName in [
      'Standalone — tile Build port enabled',
      'Standalone — tile Build port disabled',
      'Standalone — tile Build port hidden',
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
      'enabled story shows an enabled Build port inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Build port enabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtIconAction>(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.anchor,
          ),
        );
        expect(action.enabled, isTrue);
      },
    );

    testWidgets(
      'disabled story shows a disabled Build port inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Build port disabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtIconAction>(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.anchor,
          ),
        );
        expect(action.enabled, isFalse);
      },
    );

    testWidgets(
      'hidden story omits the Build port inline action',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — tile Build port hidden',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is CtIconAction && w.icon == Icons.anchor,
          ),
          findsNothing,
        );
      },
    );
  });
}
