// Widgetbook variants for Build fort payoff gist (Refs #4668).

import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_gist_line.dart';
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

  const overlayFolder = 'Province Overlay';
  final l10n = AppLocalizationsEn();

  final overlayCases = [
    'Standalone — Build fort payoff open to wood',
    'Standalone — Build fort payoff wood to stone',
    'Standalone — Build fort payoff stone to modern',
  ];

  group('Build fort payoff Widgetbook variants (Refs #4668)', () {
    for (final useCaseName in overlayCases) {
      testWidgets('$useCaseName is wired into provinceOverlayDirectories', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: overlayFolder,
          useCaseName: useCaseName,
        );
        expect(useCase.builder, isNotNull);
      });
    }

    testWidgets('open to wood overlay story shows the default-visible gist', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: overlayFolder,
        useCaseName: overlayCases.first,
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
      expect(find.byKey(kBuildFortPayoffGistKey), findsOneWidget);
    });
  });
}
