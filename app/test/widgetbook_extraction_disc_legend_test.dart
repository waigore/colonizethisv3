// Pins Extraction disc legend Widgetbook hidden/visible chrome (Refs #4367 AC7).
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('visible story mounts legend above corner controls', (
    tester,
  ) async {
    await pumpWidgetbookStory(
      tester,
      extractionDiscLegendDirectories,
      folder: 'Extraction disc legend',
      useCase: 'Visible — legend above corner controls',
    );
    expect(find.byKey(kExtractionDiscLegendKey), findsOneWidget);
    expect(find.byType(GameMapCornerControls), findsOneWidget);
  });

  testWidgets('terrain-only story hides legend and keeps corner controls', (
    tester,
  ) async {
    await pumpWidgetbookStory(
      tester,
      extractionDiscLegendDirectories,
      folder: 'Extraction disc legend',
      useCase: 'Hidden — terrain only',
    );
    expect(find.byKey(kExtractionDiscLegendKey), findsNothing);
    expect(find.byType(GameMapCornerControls), findsOneWidget);
    final GameMapCornerControls row = tester.widget(
      find.byType(GameMapCornerControls),
    );
    expect(row.homeToCapitalEnabled, isTrue);
  });

  testWidgets(
    'global-observe story hides legend and disables home-to-capital',
    (tester) async {
      await pumpWidgetbookStory(
        tester,
        extractionDiscLegendDirectories,
        folder: 'Extraction disc legend',
        useCase: 'Hidden — global observe',
      );
      expect(find.byKey(kExtractionDiscLegendKey), findsNothing);
      expect(find.byType(GameMapCornerControls), findsOneWidget);
      final GameMapCornerControls row = tester.widget(
        find.byType(GameMapCornerControls),
      );
      expect(row.homeToCapitalEnabled, isFalse);
    },
  );
}
