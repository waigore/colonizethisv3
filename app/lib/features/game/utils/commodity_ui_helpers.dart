import 'package:colonizethis_data/colonizethis_data.dart';

import '../../../l10n/l10n.dart';

String commodityDisplayName(String commodityId) {
  return CommodityCatalog.byId[commodityId]?.displayName ?? commodityId;
}

/// Localized lowercase category name for [category] (e.g. `manufactured`),
/// used in resource-icon tooltips. See
/// `SPEC/ui/components/resource-icon-tooltip.md`.
String commodityCategoryDisplayName(
  AppLocalizations l10n,
  CommodityCategory category,
) {
  switch (category) {
    case CommodityCategory.food:
      return l10n.commodityCategory_food;
    case CommodityCategory.rawMaterial:
      return l10n.commodityCategory_rawMaterial;
    case CommodityCategory.manufactured:
      return l10n.commodityCategory_manufactured;
    case CommodityCategory.luxury:
      return l10n.commodityCategory_luxury;
    case CommodityCategory.riches:
      return l10n.commodityCategory_riches;
    case CommodityCategory.advanced:
      return l10n.commodityCategory_advanced;
  }
}

/// Tooltip message for a commodity resource icon, combining its display name
/// and localized category — e.g. `Fabric (manufactured)`. Falls back to the
/// raw id with no category when the commodity is not in the catalog.
String commodityIconTooltip(AppLocalizations l10n, String commodityId) {
  final commodity = CommodityCatalog.byId[commodityId];
  if (commodity == null) return commodityId;
  return l10n.trainDialog_costCommodityTooltip(
    commodity.displayName ?? commodityId,
    commodityCategoryDisplayName(l10n, commodity.category),
  );
}
