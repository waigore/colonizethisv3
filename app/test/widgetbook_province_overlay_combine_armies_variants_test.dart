// Widget test pin for Province Overlay Military Combine variants (Refs #4610).

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

  group('Province Overlay Combine Widgetbook variants (Refs #4610)', () {
    for (final useCaseName in [
      'Standalone — Military Combine enabled',
      'Standalone — Military Combine Home Army target',
      'Standalone — Military Combine pending-move disabled',
      'Standalone — Military Combine hidden',
    ]) {
      testWidgets('$useCaseName is wired into provinceOverlayDirectories', (
        tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: useCaseName,
        );
        expect(useCase.builder, isNotNull);
      });
    }

    testWidgets('enabled Combine story shows enabled Combine control', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Military Combine enabled',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      await revealProvinceOverlayWideSection(
        tester,
        sectionTitle: l10n.provinceOverlay_sectionMilitary,
      );
      final action = tester.widget<CtActionTextButton>(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_combineArmiesAction,
        ),
      );
      expect(action.enabled, isTrue);
    });
  });
}
