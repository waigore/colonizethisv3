// Widget test pin for Province Overlay Naval Blockade/Beachhead variants
// (Refs #4413).

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

  group('Province Overlay Naval mission Widgetbook variants (Refs #4413)', () {
    for (final useCaseName in [
      'Standalone — Naval Blockade enabled',
      'Standalone — Naval Blockade disabled',
      'Standalone — Naval Blockade hidden',
      'Standalone — Naval Beachhead enabled',
      'Standalone — Naval Beachhead disabled',
      'Standalone — Naval Beachhead hidden',
      'Standalone — Naval Blockade/Beachhead 320 dp',
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

    testWidgets('enabled Blockade story shows enabled Blockade control', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Blockade enabled',
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
          l10n.provinceOverlay_blockadeAction,
        ),
      );
      expect(action.enabled, isTrue);
      expect(action.onPressed, isNotNull);
    });

    testWidgets('hidden Beachhead story has no Beachhead control', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Beachhead hidden',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_beachheadAction,
        ),
        findsNothing,
      );
    });
  });
}
