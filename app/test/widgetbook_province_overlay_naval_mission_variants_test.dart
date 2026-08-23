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
      'Standalone — Naval Under blockade',
      'Standalone — Naval Under blockade capital',
      'Standalone — Naval sea-zone Patrol/Defend enabled',
      'Standalone — Naval sea-zone Patrol/Defend disabled',
      'Standalone — Naval sea-zone Patrol/Defend hidden',
      'Standalone — Naval sea-zone Patrol/Defend 320 dp',
      'Standalone — Naval sea-zone pending mission preview',
      'Standalone — Naval sea-zone pending move preview',
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

    testWidgets('Under blockade story shows owned-port status copy', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Under blockade',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.provinceOverlay_underBlockade), findsOneWidget);
    });

    testWidgets('Under blockade capital story shows capital-port status copy', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval Under blockade capital',
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.provinceOverlay_underBlockadeCapital),
        findsOneWidget,
      );
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

    testWidgets('enabled sea-zone Patrol story shows enabled Patrol', (
      tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: folderName,
        useCaseName: 'Standalone — Naval sea-zone Patrol/Defend enabled',
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
          l10n.provinceOverlay_patrolAction,
        ),
      );
      expect(action.enabled, isTrue);
      expect(action.onPressed, isNotNull);
    });
  });
}
