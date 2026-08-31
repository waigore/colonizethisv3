// Widget test pin for Province Overlay Naval Detach and sail variants
// (Refs #4448).

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
    'Province Overlay Detach and sail Widgetbook variants (Refs #4448)',
    () {
      for (final useCaseName in [
        'Standalone — Naval Detach and sail enabled',
        'Standalone — Naval Detach and sail hidden',
        'Standalone — Naval Detach and sail 320 dp',
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

      testWidgets('enabled story shows enabled Detach and sail control', (
        tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Naval Detach and sail enabled',
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
            l10n.provinceOverlay_detachAndSailAction,
          ),
        );
        expect(action.enabled, isTrue);
        expect(action.onPressed, isNotNull);
      });
    },
  );
}
