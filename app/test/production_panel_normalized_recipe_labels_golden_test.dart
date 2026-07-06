// Visual golden for normalized production recipe allocation labels (Refs #3873).
//
// AC#8: Production panel Allocation subpanel shows catalog-driven recipe
// labels with tobacco×2, timber×2, and iron×1 + coal×1 for cigars, paper, and
// steel respectively. SPEC: SPEC/ui/production-panel.md § Behaviour.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

import 'production_panel_test_fixtures.dart';
import 'support/app_shell_harness.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: allocation subpanel shows normalized recipe labels (Refs #3873)',
    (WidgetTester tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;

      final player = productionPanelTestFullPlayer();
      final game = productionPanelTestGameFor(player);

      await pumpAppShell(
        tester,
        viewport: const Size(900, 780),
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        settle: true,
        child: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('production_panel_normalized_labels_golden'),
            child: ProductionPanel(
              game: game,
              player: player,
              desiredOutputByRecipe: const {},
              netDeltasByCommodity: const {},
              onDesiredOutputChanged: (_) {},
            ),
          ),
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
        find.byKey(
          const ValueKey('production_panel_normalized_labels_golden'),
        ),
        matchesGoldenFile(
          'goldens/production_panel_normalized_recipe_labels.png',
        ),
      );
    },
  );
}
