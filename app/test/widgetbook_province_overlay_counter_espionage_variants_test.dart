// Widget test pin for Province Overlay Civilian Counter-espionage variants (Refs #4528).

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
    'Province Overlay Counter-espionage Widgetbook variants (Refs #4528)',
    () {
      for (final useCaseName in [
        'Standalone — Civilian Counter-espionage enabled',
        'Standalone — Civilian Counter-espionage disabled (no idle Spy)',
        'Standalone — Civilian Counter-espionage disabled (already posted)',
        'Standalone — Civilian Counter-espionage hidden',
        'Standalone — Civilian Counter-espionage enabled (320 dp)',
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

      testWidgets('enabled Counter-espionage story shows enabled control', (
        tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Civilian Counter-espionage enabled',
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 640),
        );
        await tester.pumpAndSettle();
        await revealProvinceOverlayWideSection(
          tester,
          sectionTitle: l10n.provinceOverlay_sectionCivilian,
        );
        final action = tester.widget<CtActionTextButton>(
          find.widgetWithText(
            CtActionTextButton,
            l10n.provinceOverlay_counterEspionageAction,
          ),
        );
        expect(action.enabled, isTrue);
        expect(action.onPressed, isNotNull);
        expect(
          find.text(l10n.provinceOverlay_counterEspionageGist),
          findsOneWidget,
        );
      });

      testWidgets('hidden Counter-espionage story has no control', (
        tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: 'Standalone — Civilian Counter-espionage hidden',
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
            l10n.provinceOverlay_counterEspionageAction,
          ),
          findsNothing,
        );
      });
    },
  );
}
