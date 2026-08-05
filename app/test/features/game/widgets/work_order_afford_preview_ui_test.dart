import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

void main() {
  test('workOrderAffordStatusLine reports material shortfall', () {
    final l10n = AppLocalizationsEn();
    final line = workOrderAffordStatusLine(
      l10n: l10n,
      preview: WorkOrderAffordPreview(
        materialCosts: {'lumber': 2},
        canAfford: false,
        materialShortfalls: [(commodityId: 'lumber', quantity: 1)],
      ),
    );
    expect(line, contains('Short:'));
    expect(line, contains('Lumber'));
  });

  test('formatWorkOrderMaterialCostSummary joins commodity labels', () {
    final summary = formatWorkOrderMaterialCostSummary({
      'lumber': 1,
      'castIron': 2,
    });
    expect(summary, contains('1'));
    expect(summary, contains('2'));
  });
}
