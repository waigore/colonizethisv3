// Visual golden for normalized production recipe allocation labels (Refs #3873).
//
// AC#8: Production panel Allocation subpanel shows catalog-driven recipe
// labels with tobacco×2, timber×2, and iron×1 + coal×1 for cigars, paper, and
// steel respectively. SPEC: SPEC/ui/production-panel.md § Behaviour.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';

import 'production_panel_test_support.dart';
import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: allocation subpanel shows normalized recipe labels (Refs #3873)',
    (WidgetTester tester) async {
      final player = productionPanelTestFullPlayer();
      final game = productionPanelTestGameFor(player);
      const boundaryKey = ValueKey('production_panel_normalized_labels_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(900, 780),
        includeLocalizations: true,
        child: ProductionPanel(
          game: game,
          player: player,
          desiredOutputByRecipe: const {},
          netDeltasByCommodity: const {},
          onDesiredOutputChanged: (_) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Tobacco ×2'), findsOneWidget);
      expect(find.textContaining('Timber ×2'), findsAtLeastNWidgets(2));
      expect(find.textContaining('Iron ×1, Coal ×1'), findsOneWidget);
      expect(find.textContaining('×3'), findsNothing);
      expect(find.textContaining('Cast Iron'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_panel_normalized_recipe_labels.png',
        ),
      );
    },
  );
}
