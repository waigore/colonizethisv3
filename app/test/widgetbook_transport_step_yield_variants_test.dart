// Widgetbook variants for transport-step payoff gist (Refs #4663).

import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_gist_line.dart';
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
  const radialFolder = 'Tile Context Radial';
  const affordFolder = 'Work order afford preview';

  final overlayCases = [
    'Standalone — transport step yield raise',
    'Standalone — transport step yield road cap',
    'Standalone — transport step yield town cap',
    'Standalone — transport step yield disconnected',
    'Standalone — transport step yield binds capital',
    'Standalone — transport step yield port on coast',
  ];

  group('Transport-step payoff Widgetbook variants (Refs #4663)', () {
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

    testWidgets('raise overlay story shows the default-visible gist', (
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
      expect(find.byKey(kTransportStepYieldGistKey), findsOneWidget);
      expect(find.textContaining('if still linked'), findsWidgets);
    });

    testWidgets('radial raise caption is catalogued', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        tileRadialDirectories,
        folderName: radialFolder,
        useCaseName: 'Transport step yield raise',
      );
      expect(useCase.builder, isNotNull);
    });

    testWidgets('work-order afford raise variant is catalogued', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        workOrderAffordPreviewDirectories,
        folderName: affordFolder,
        useCaseName: 'Selection prompt — transport step yield raise',
      );
      expect(useCase.builder, isNotNull);
    });
  });
}
