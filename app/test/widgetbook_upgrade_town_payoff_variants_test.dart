// Widgetbook variants for Upgrade town payoff gist (Refs #4747).

import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_gist_line.dart';
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
  const overlayCases = [
    'Standalone — Upgrade town payoff start',
    'Standalone — Upgrade town payoff pause until 4',
    'Standalone — Upgrade town payoff 320 dp',
  ];

  group('Upgrade town payoff Widgetbook variants (Refs #4747)', () {
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

    testWidgets('pause overlay story shows the default-visible gist', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        provinceOverlayDirectories,
        folderName: overlayFolder,
        useCaseName: overlayCases[1],
      );
      await pumpWidgetbookUseCaseAtSize(
        tester,
        useCase,
        size: const Size(800, 640),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kUpgradeTownPayoffGistKey), findsOneWidget);
    });
  });
}
