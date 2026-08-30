// Pins Improvement headroom legend Widgetbook chrome (Refs #4408).
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/controls/improvement_headroom_legend.dart';
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
      improvementHeadroomLegendDirectories,
      folder: 'Improvement headroom legend',
      useCase: 'Visible — legend above corner controls',
    );
    expect(find.byKey(kImprovementHeadroomLegendKey), findsOneWidget);
    expect(find.byType(GameMapCornerControls), findsOneWidget);
  });

  testWidgets('improvements-off story hides legend', (tester) async {
    await pumpWidgetbookStory(
      tester,
      improvementHeadroomLegendDirectories,
      folder: 'Improvement headroom legend',
      useCase: 'Hidden — improvements off',
    );
    expect(find.byKey(kImprovementHeadroomLegendKey), findsNothing);
    expect(find.byType(GameMapCornerControls), findsOneWidget);
  });

  testWidgets('global-observe story hides legend', (tester) async {
    await pumpWidgetbookStory(
      tester,
      improvementHeadroomLegendDirectories,
      folder: 'Improvement headroom legend',
      useCase: 'Hidden — global observe',
    );
    expect(find.byKey(kImprovementHeadroomLegendKey), findsNothing);
  });
}
