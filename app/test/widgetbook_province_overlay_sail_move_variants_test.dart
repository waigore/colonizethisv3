// Widget test pin for Province Overlay Naval Sail / Move variants
// (Refs #4735).

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

  group('Province Overlay Sail / Move Widgetbook variants (Refs #4735)', () {
    for (final useCaseName in [
      'Standalone — Naval Sail / Move sea enabled',
      'Standalone — Naval Sail / Move multi-fleet',
      'Standalone — Naval Sail / Move hidden',
      'Standalone — Naval Sail / Move in-port enabled',
      'Standalone — Naval Sail / Move capital with Transfer',
      'Standalone — Naval Sail / Move 320 dp',
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

    testWidgets('sea enabled story shows enabled Sail / Move control', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Sail / Move sea enabled',
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
        find.widgetWithText(CtActionTextButton, l10n.naval_mission_sail),
      );
      expect(action.enabled, isTrue);
      expect(action.onPressed, isNotNull);
    });
  });
}
