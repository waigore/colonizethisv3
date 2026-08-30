// Widget test pin for `Province Overlay` Political Upgrade town variants.
// Refs #4316 — document-app-ui MAP20001 Political Upgrade town behavior/variants.

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
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
  final l10n = AppLocalizationsEn();

  group('Province Overlay Upgrade town Widgetbook variants (Refs #4316)', () {
    for (final useCaseName in [
      'Standalone — Political Upgrade town enabled',
      'Standalone — Political Upgrade town disabled',
      'Standalone — Political Upgrade town hidden',
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
      'enabled story shows an enabled Upgrade town political control',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Political Upgrade town enabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, l10n.provinceOverlay_upgradeTownAction),
        );
        expect(action.enabled, isTrue);
        expect(action.onPressed, isNotNull);
      },
    );

    testWidgets(
      'disabled story shows a disabled Upgrade town political control',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Political Upgrade town disabled',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        final action = tester.widget<CtActionTextButton>(
          find.widgetWithText(CtActionTextButton, l10n.provinceOverlay_upgradeTownAction),
        );
        expect(action.enabled, isFalse);
        expect(action.onPressed, isNull);
      },
    );

    testWidgets(
      'hidden story omits the Upgrade town political control',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Political Upgrade town hidden',
        );

        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(CtActionTextButton, l10n.provinceOverlay_upgradeTownAction),
          findsNothing,
        );
      },
    );
  });
}
