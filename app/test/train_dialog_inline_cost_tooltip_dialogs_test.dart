// Pins the resource-icon tooltip convention for the shared
// SPEC: `SPEC/ui/components/resource-icon-tooltip.md`,
// `SPEC/ui/components/train-dialog-chrome.md`,
// `SPEC/ui/train-military-dialog.md`, `SPEC/ui/train-naval-dialog.md`.
// Refs #3631.
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

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';
import 'train_dialog_inline_cost_tooltip_support.dart';

  group('Train Military dialog cost-icon tooltips (UNIT50001)', () {
    testWidgets(
      'AC: treasury / peasant / commodity cost icons carry resource-name '
      'tooltips',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainInlineCostDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: trainInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        expect(find.byTooltip('Treasury'), findsWidgets);
        expect(find.byTooltip('Peasants'), findsWidgets);
        // At least one commodity cost icon names its commodity + category.
        expect(
          trainInlineCostTooltipMessages(tester).any(
            (m) => m.contains('(manufactured)') || m.contains('(raw material)'),
          ),
          isTrue,
          reason:
              'Train Military regiment cost icons must expose a '
              '"{name} ({category})" tooltip per '
              'SPEC/ui/components/resource-icon-tooltip.md.',
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
        await pumpTrainInlineCostDialog(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: trainInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        expect(find.byTooltip('Treasury'), findsWidgets);
        expect(find.byTooltip('Peasants'), findsWidgets);
        expect(
          trainInlineCostTooltipMessages(tester).any(
            (m) => m.contains('(manufactured)') || m.contains('(raw material)'),
          ),
          isTrue,
          reason:
              'Train Naval ship cost icons must expose a '
              '"{name} ({category})" tooltip per '
              'SPEC/ui/components/resource-icon-tooltip.md.',
        );
      },
    );
  });

  group('cost-summary icon size (#3631 Phase 2 legibility)', () {
    test('shared cost-icon size constant is 30 dp', () {
      expect(kTrainDialogCostIconSize, 30);
    });

    /// Asserts every commodity / treasury / peasant icon nested inside a
    /// [TrainDialogInlineCost] renders at [kTrainDialogCostIconSize] (30 dp)
    /// and each cost segment keeps its >= 44 dp touch target.
    Future<void> expectEnlargedCostIcons(WidgetTester tester) async {
      final Finder treasuryIcon = find.descendant(
        of: find.byType(TrainDialogInlineCost),
        matching: find.byIcon(Icons.payments_outlined),
      );
      expect(treasuryIcon, findsWidgets);
      for (final Icon icon in tester.widgetList<Icon>(treasuryIcon)) {
        expect(icon.size, kTrainDialogCostIconSize);
      }

      final Finder peasantIcon = find.descendant(
        of: find.byType(TrainDialogInlineCost),
        matching: find.byType(WorkerIcon),
      );
      expect(peasantIcon, findsWidgets);
      for (final WorkerIcon icon in tester.widgetList<WorkerIcon>(
        peasantIcon,
      )) {
        expect(icon.size, kTrainDialogCostIconSize);
      }

      final Finder commodityIcon = find.descendant(
        of: find.byType(TrainDialogInlineCost),
        matching: find.byType(ResourceIcon),
      );
      expect(commodityIcon, findsWidgets);
      for (final ResourceIcon icon in tester.widgetList<ResourceIcon>(
        commodityIcon,
      )) {
        expect(icon.size, kTrainDialogCostIconSize);
      }

      // Larger icons must still nest inside the >= 44 dp touch target.
      final int segments = find.byType(TrainDialogInlineCost).evaluate().length;
      for (int i = 0; i < segments; i++) {
        final Size size = tester.getSize(
          find.byType(TrainDialogInlineCost).at(i),
        );
        expect(size.height, greaterThanOrEqualTo(kMinTouchTargetSize));
        expect(size.width, greaterThanOrEqualTo(kMinTouchTargetSize));
      }
    }

    testWidgets(
      'AC (positive): Train Military (UNIT50001) cost icons render at 30 dp',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainInlineCostDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: trainInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );
        await expectEnlargedCostIcons(tester);
      },
    );

    testWidgets(
      'AC (positive): Train Naval (UNIT60001) cost icons render at 30 dp',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainInlineCostDialog(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: trainInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );
        await expectEnlargedCostIcons(tester);
      },
    );

    testWidgets(
      'AC (negative): resource-bar chips stay small (14 dp), so the size bump '
      'is scoped to the cost summary',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await pumpTrainInlineCostDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: trainInlineCostHumanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        // The resource-bar peasant chip icon is NOT a cost-summary icon and
        // must remain 14 dp (out of #3631 Phase 2 scope).
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
