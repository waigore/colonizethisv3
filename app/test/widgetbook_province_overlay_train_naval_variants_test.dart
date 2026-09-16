// Widget test pin for Province Overlay Naval Train variants (Refs #4776).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
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

  group('Province Overlay Naval Train Widgetbook variants (Refs #4776)', () {
    for (final useCaseName in [
      'Standalone — Naval Train enabled',
      'Standalone — Naval Train hidden',
      'Standalone — Naval Train 320 dp',
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

    testWidgets('enabled Train story shows enabled Train control', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Train enabled',
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
        find.byKey(kProvinceOverlayTrainNavalKey),
      );
      expect(action.enabled, isTrue);
      expect(action.onPressed, isNotNull);
      expect(action.label, l10n.provinceOverlay_trainNavalAction);
      expect(find.text(l10n.provinceOverlay_trainNavalGist), findsOneWidget);
    });

    testWidgets('hidden Train story has no Train control', (tester) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Train hidden',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kProvinceOverlayTrainNavalKey), findsNothing);
    });
  });
}
