// Pins the resource-icon tooltip convention for the shared
// `TrainDialogInlineCost` cost segment and its application in the Train
// Military (`UNIT50001`) and Train Naval (`UNIT60001`) dialogs.
//
// SPEC: `SPEC/ui/components/resource-icon-tooltip.md`,
// `SPEC/ui/components/train-dialog-chrome.md`,
// `SPEC/ui/train-military-dialog.md`, `SPEC/ui/train-naval-dialog.md`.
// Refs #3631.
//
// The convention requires every icon-only resource glyph (commodity,
// treasury coin, peasant worker) in a per-unit-row cost summary to:
//
//  * carry a `Tooltip` (`TooltipTriggerMode.tap` — hover on desktop, tap on
//    mobile) whose message names the resource;
//  * expose a `>= kMinTouchTargetSize` (44 dp) trigger region so it is
//    reachable on narrow mobile viewports.

import 'dart:io' show File;

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/utils/commodity_ui_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/train_dialog_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_naval_dialog.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';
import 'support/panel_test_fixtures.dart';

Widget _localizedHost(Widget child) {
  return buildAppShell(
    child: Scaffold(body: Center(child: child)),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

String _humanPlayerId(Game game) =>
    game.players.firstWhere((p) => p.isHuman).id;

Future<void> _pumpDialog(WidgetTester tester, Widget dialog) async {
  await pumpAppShell(
    tester,
    viewport: const Size(420, 900),
    child: Scaffold(body: dialog),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    settle: true,
  );
}

/// Collects every mounted [Tooltip] message string.
List<String> _tooltipMessages(WidgetTester tester) {
  return tester
      .widgetList<Tooltip>(find.byType(Tooltip))
      .map((t) => t.message ?? '')
      .toList();
}

void main() {
  suppressLogsForTests();

  group('TrainDialogInlineCost (resource-icon-tooltip convention)', () {
    testWidgets(
      'AC (positive): wraps the icon in a tap-trigger Tooltip with the given '
      'message and a >= 44 dp touch target',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _localizedHost(
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
          _localizedHost(
            const TrainDialogInlineCost(
              icon: SizedBox(width: 14, height: 14),
              label: '1',
              tooltipMessage: 'Peasants',
            ),
          ),
        );

        // Before any interaction the message is only on the Tooltip widget,
        // not yet painted in an overlay.
        await tester.tap(find.byType(Tooltip));
        await tester.pump(const Duration(seconds: 1));

        // After the tap, the tooltip overlay text is present (in addition to
        // the Tooltip widget's own message field).
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
        _localizedHost(
          Builder(
            builder: (BuildContext context) {
              l10n = appL10n(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(commodityIconTooltip(l10n, 'fabric'), 'Fabric (manufactured)');
      expect(commodityIconTooltip(l10n, 'castIron'), 'Cast iron (manufactured)');
      expect(commodityIconTooltip(l10n, 'coal'), 'Coal (raw material)');
      expect(commodityIconTooltip(l10n, 'grain'), 'Grain (food)');
      expect(commodityIconTooltip(l10n, 'gold'), 'Gold (riches)');
      // Negative: an id absent from CommodityCatalog returns just the id.
      expect(commodityIconTooltip(l10n, 'definitely_not_a_commodity'),
          'definitely_not_a_commodity');

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
        await _pumpDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: _humanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        expect(find.byTooltip('Treasury'), findsWidgets);
        expect(find.byTooltip('Peasants'), findsWidgets);
        // At least one commodity cost icon names its commodity + category.
        expect(
          _tooltipMessages(tester).any(
            (m) =>
                m.contains('(manufactured)') || m.contains('(raw material)'),
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
        await _pumpDialog(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: _humanPlayerId(game),
            currentOrders: const Orders(),
            bus: AppEventBus.create(),
          ),
        );

        expect(find.byTooltip('Treasury'), findsWidgets);
        expect(find.byTooltip('Peasants'), findsWidgets);
        expect(
          _tooltipMessages(tester).any(
            (m) =>
                m.contains('(manufactured)') || m.contains('(raw material)'),
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
      for (final WorkerIcon icon
          in tester.widgetList<WorkerIcon>(peasantIcon)) {
        expect(icon.size, kTrainDialogCostIconSize);
      }

      final Finder commodityIcon = find.descendant(
        of: find.byType(TrainDialogInlineCost),
        matching: find.byType(ResourceIcon),
      );
      expect(commodityIcon, findsWidgets);
      for (final ResourceIcon icon
          in tester.widgetList<ResourceIcon>(commodityIcon)) {
        expect(icon.size, kTrainDialogCostIconSize);
      }

      // Larger icons must still nest inside the >= 44 dp touch target.
      final int segments = find.byType(TrainDialogInlineCost).evaluate().length;
      for (int i = 0; i < segments; i++) {
        final Size size = tester.getSize(find.byType(TrainDialogInlineCost).at(i));
        expect(size.height, greaterThanOrEqualTo(kMinTouchTargetSize));
        expect(size.width, greaterThanOrEqualTo(kMinTouchTargetSize));
      }
    }

    testWidgets(
      'AC (positive): Train Military (UNIT50001) cost icons render at 30 dp',
      (WidgetTester tester) async {
        final game = buildTrainPanelTestGame();
        await _pumpDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: _humanPlayerId(game),
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
        await _pumpDialog(
          tester,
          TrainNavalDialog(
            game: game,
            humanPlayerId: _humanPlayerId(game),
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
        await _pumpDialog(
          tester,
          TrainMilitaryDialog(
            game: game,
            humanPlayerId: _humanPlayerId(game),
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
        for (final WorkerIcon icon
            in tester.widgetList<WorkerIcon>(barPeasant)) {
          expect(icon.size, 14);
        }
      },
    );
  });

  group('_InlineCost de-duplication guard', () {
    test(
      'the private _InlineCost class lives nowhere — the shared '
      'TrainDialogInlineCost is the single source',
      () {
        final String military = File(
          'lib/features/game/widgets/train_military_dialog.dart',
        ).readAsStringSync();
        final String naval = File(
          'lib/features/game/widgets/train_naval_dialog.dart',
        ).readAsStringSync();
        final String chrome = File(
          'lib/features/game/widgets/train_dialog_chrome.dart',
        ).readAsStringSync();
        // Refs #3686: the military/naval cost rows (incl. the inline cost
        // segments) are now rendered by the shared commodity-cost base, so the
        // single `TrainDialogInlineCost` reference lives there rather than in
        // each thin dialog file.
        final String commodityCostBase = File(
          'lib/features/game/widgets/train_commodity_cost_dialog_base.dart',
        ).readAsStringSync();

        expect(
          military.contains('class _InlineCost'),
          isFalse,
          reason: 'train_military_dialog.dart must not redeclare _InlineCost.',
        );
        expect(
          naval.contains('class _InlineCost'),
          isFalse,
          reason: 'train_naval_dialog.dart must not redeclare _InlineCost.',
        );
        expect(
          commodityCostBase.contains('class _InlineCost'),
          isFalse,
          reason:
              'train_commodity_cost_dialog_base.dart must not redeclare '
              '_InlineCost.',
        );
        expect(
          chrome.contains('class TrainDialogInlineCost'),
          isTrue,
          reason:
              'TrainDialogInlineCost must be the single shared cost segment in '
              'train_dialog_chrome.dart.',
        );
        expect(commodityCostBase.contains('TrainDialogInlineCost'), isTrue);
      },
    );
  });
}
