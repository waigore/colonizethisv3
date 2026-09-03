// ProductionPanel Allocation affordance copy ACs. SPEC/ui/production-panel.md (Refs #4717).
// Shared pump/finder helpers: production_panel_widget_helpers.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_panel_widget_helpers.dart';
import 'production_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel allocation affordance copy', () {
    testWidgets(
      'Allocation rows show player-facing affordance copy (Refs #4717)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);
        final l10n = productionEnL10n();

        expect(find.textContaining('Up to'), findsWidgets);
        expect(find.textContaining('limited by'), findsWidgets);
        expect(find.textContaining('·'), findsNothing);
        expect(find.textContaining('bottleneck'), findsNothing);

        final tooltip = find.byWidgetPredicate(
          (Widget w) =>
              w is Tooltip &&
              w.message == l10n.production_recipeAffordanceTooltip,
        );
        expect(tooltip, findsWidgets);
      },
    );

    testWidgets(
      'timber claimed elsewhere shows Cannot run short of Timber (Refs #4717)',
      (WidgetTester tester) async {
        final player = productionPanelTestFullPlayer().copyWith(
          stockpile: productionPanelTestFullPlayer().stockpile.applyDelta(
            CommodityCatalog.timber.id,
            -96,
          ),
        );
        await pumpProductionPanelSettled(
          tester,
          player: player,
          desiredOutputByRecipe: const {'paper_from_timber': 2},
        );

        expect(
          find.text('Cannot run — short of Timber'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'labour committed elsewhere shows Cannot run not enough labour (Refs #4717)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: productionPanelTestPartialPlayer(),
          desiredOutputByRecipe: const {'lumber_from_timber': 1},
        );

        expect(
          find.text('Cannot run — not enough labour left this turn'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      '320 dp affordance copy wraps without overflow or ellipsis (Refs #4717)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          width: 320,
          height: 640,
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Up to'), findsWidgets);
        expect(find.textContaining('limited by'), findsWidgets);

        final affordanceTexts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(Tooltip),
                matching: find.byType(Text),
              ),
            )
            .where(
              (t) =>
                  t.data != null &&
                  (t.data!.contains('Up to') ||
                      t.data!.contains('Cannot run')),
            );
        expect(affordanceTexts, isNotEmpty);
        expect(
          affordanceTexts.every((t) => t.overflow != TextOverflow.ellipsis),
          isTrue,
        );
      },
    );
  });
}
