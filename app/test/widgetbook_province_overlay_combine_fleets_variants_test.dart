// Widget test pin for Province Overlay Naval Combine variants (Refs #4659).

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

  group('Province Overlay Naval Combine Widgetbook variants (Refs #4659)', () {
    for (final useCaseName in [
      'Standalone — Naval Combine enabled',
      'Standalone — Naval Combine Home Fleet target',
      'Standalone — Naval Combine sea-zone enabled',
      'Standalone — Naval Combine pending-order disabled',
      'Standalone — Naval Combine Home + non-transfer-eligible source',
      'Standalone — Naval Combine hidden',
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
        useCaseName: 'Standalone — Naval Combine enabled',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      final action = tester.widget<CtActionTextButton>(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_combineFleetsAction,
        ),
      );
      expect(action.enabled, isTrue);
    });
  });
}
