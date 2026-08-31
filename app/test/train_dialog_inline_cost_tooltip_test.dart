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

void main() {
  suppressLogsForTests();

  group('TrainDialogInlineCost (resource-icon-tooltip convention)', () {
    testWidgets(
      'AC (positive): wraps the icon in a tap-trigger Tooltip with the given '
      'message and a >= 44 dp touch target',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          trainInlineCostLocalizedHost(
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
          trainInlineCostLocalizedHost(
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
        trainInlineCostLocalizedHost(
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
      // Negative: an id absent from CommodityCatalog returns just the id.
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
}
