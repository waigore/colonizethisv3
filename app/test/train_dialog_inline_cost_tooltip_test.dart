import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/production/commodity_ui_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_dialog_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'train_dialog_inline_cost_tooltip_support.dart';

void main() {
  suppressLogsForTests();

  group('TrainDialogInlineCost (resource-icon-tooltip convention)', () {
    testWidgets(
      'AC (positive): wraps the icon in a tap-trigger Tooltip with the given '
      'message and a >= 44 dp touch target',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          trainDialogInlineCostLocalizedHost(
            const TrainDialogInlineCost(
              icon: SizedBox(width: 14, height: 14),
              label: '3',
              tooltipMessage: 'Treasury',
            ),
          ),
        );

        expect(find.byType(Tooltip), findsOneWidget);
        final Tooltip tooltip = tester.widget(find.byType(Tooltip));
        expect(tooltip.message, 'Treasury');
        expect(tooltip.triggerMode, TooltipTriggerMode.tap);
        expect(find.text('3'), findsOneWidget);

        final Size size = tester.getSize(find.byType(Tooltip));
        expect(
          size.height,
          greaterThanOrEqualTo(kMinTouchTargetSize),
          reason:
              'SPEC/ui/components/resource-icon-tooltip.md: the tooltip-trigger '
              'region must be at least kMinTouchTargetSize (44 dp) tall.',
        );
        expect(
          size.width,
          greaterThanOrEqualTo(kMinTouchTargetSize),
          reason:
              'SPEC/ui/components/resource-icon-tooltip.md: the tooltip-trigger '
              'region must be at least kMinTouchTargetSize (44 dp) wide.',
        );
      },
    );

    testWidgets(
      'AC (positive): tapping the icon surfaces the tooltip message overlay '
      '(mobile tap affordance)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          trainDialogInlineCostLocalizedHost(
            const TrainDialogInlineCost(
              icon: SizedBox(width: 14, height: 14),
              label: '1',
              tooltipMessage: 'Peasants',
            ),
          ),
        );

        await tester.tap(find.byType(Tooltip));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Peasants'), findsOneWidget);
      },
    );
  });

  group('commodityIconTooltip / commodityCategoryDisplayName helpers', () {
    testWidgets('AC (positive + negative): commodity tooltip combines display '
        'name and category; unknown id falls back to the raw id', (
      WidgetTester tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        trainDialogInlineCostLocalizedHost(
          Builder(
            builder: (BuildContext context) {
              l10n = appL10n(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(commodityIconTooltip(l10n, 'fabric'), 'Fabric (manufactured)');
      expect(
        commodityIconTooltip(l10n, 'castIron'),
        'Cast iron (manufactured)',
      );
      expect(commodityIconTooltip(l10n, 'coal'), 'Coal (raw material)');
      expect(commodityIconTooltip(l10n, 'grain'), 'Grain (food)');
      expect(commodityIconTooltip(l10n, 'gold'), 'Gold (riches)');
      expect(
        commodityIconTooltip(l10n, 'definitely_not_a_commodity'),
        'definitely_not_a_commodity',
      );

      expect(
        commodityCategoryDisplayName(l10n, CommodityCategory.advanced),
        'advanced',
      );
      expect(
        commodityCategoryDisplayName(l10n, CommodityCategory.luxury),
        'luxury',
      );
    });
  });

  group('Train Military dialog cost-icon tooltips (UNIT50001)', () {
    testWidgets(
      'AC: treasury / peasant / commodity cost icons carry resource-name '
      'tooltips',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainDialogInlineCostDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: trainDialogInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        expect(find.byTooltip('Treasury'), findsWidgets);
        expect(find.byTooltip('Peasants'), findsWidgets);
        expect(
          trainDialogInlineCostTooltipMessages(tester).any(
            (m) => m.contains('(manufactured)') || m.contains('(raw material)'),
          ),
          isTrue,
        );
      },
    );
  });

  group('Train Naval dialog cost-icon tooltips (UNIT60001)', () {
    testWidgets(
      'AC: treasury / peasant / commodity cost icons carry resource-name '
      'tooltips',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainDialogInlineCostDialog(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: trainDialogInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        expect(find.byTooltip('Treasury'), findsWidgets);
        expect(find.byTooltip('Peasants'), findsWidgets);
        expect(
          trainDialogInlineCostTooltipMessages(tester).any(
            (m) => m.contains('(manufactured)') || m.contains('(raw material)'),
          ),
          isTrue,
        );
      },
    );
  });

  group('cost-summary icon size (#3631 Phase 2 legibility)', () {
    test('shared cost-icon size constant is 30 dp', () {
      expect(kTrainDialogCostIconSize, 30);
    });

    testWidgets(
      'AC (positive): Train Military (UNIT50001) cost icons render at 30 dp',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainDialogInlineCostDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: trainDialogInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );
        await expectTrainDialogEnlargedCostIcons(tester);
      },
    );

    testWidgets(
      'AC (positive): Train Naval (UNIT60001) cost icons render at 30 dp',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainDialogInlineCostDialog(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: trainDialogInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );
        await expectTrainDialogEnlargedCostIcons(tester);
      },
    );

    testWidgets(
      'AC (negative): resource-bar chips stay small (14 dp), so the size bump '
      'is scoped to the cost summary',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainDialogInlineCostDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: trainDialogInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        final Finder barPeasant = find.descendant(
          of: find.byType(TrainDialogResourceChip),
          matching: find.byType(WorkerIcon),
        );
        expect(barPeasant, findsWidgets);
        for (final WorkerIcon icon in tester.widgetList<WorkerIcon>(
          barPeasant,
        )) {
          expect(icon.size, 14);
        }
      },
    );
  });
}
