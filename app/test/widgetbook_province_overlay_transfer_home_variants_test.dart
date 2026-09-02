// Widget test pin for Province Overlay Naval Transfer to Home Fleet variants
// (Refs #4625).

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widget_test_assets.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  const folderName = 'Province Overlay';
  final l10n = AppLocalizationsEn();

  group(
    'Province Overlay Transfer to Home Fleet Widgetbook variants (Refs #4625)',
    () {
      for (final useCaseName in [
        'Standalone — Naval Transfer to Home Fleet enabled',
        'Standalone — Naval Transfer to Home Fleet disabled',
        'Standalone — Naval Transfer to Home Fleet hidden',
        'Standalone — Naval Transfer to Home Fleet sea-zone enabled',
        'Standalone — Naval Transfer to Home Fleet 320 dp',
        'Standalone — Naval Transfer fleet picker',
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

      testWidgets('enabled story shows enabled Transfer control', (
        tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Naval Transfer to Home Fleet enabled',
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();
        await revealProvinceOverlayWideSection(
          tester,
          sectionTitle: l10n.provinceOverlay_sectionNaval,
        );
        final action = tester.widget<CtActionTextButton>(
          find.widgetWithText(
            CtActionTextButton,
            l10n.provinceOverlay_transferToHomeFleetAction,
          ),
        );
        expect(action.enabled, isTrue);
        expect(action.onPressed, isNotNull);
      });
    },
  );
}
