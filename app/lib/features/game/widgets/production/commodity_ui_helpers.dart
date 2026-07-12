import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Localized display name for [commodityId] from `AppLocalizations`.
///
/// Falls back to the raw id when the commodity is not in the catalog / has no
/// `commodity_<id>` key. UI paths must use this helper rather than
/// `CommodityCatalog.displayName` (Refs #3987).
String commodityDisplayName(AppLocalizations l10n, String commodityId) {
  switch (commodityId) {
    case 'grain':
      return l10n.commodity_grain;
    case 'meat':
      return l10n.commodity_meat;
    case 'timber':
      return l10n.commodity_timber;
    case 'iron':
      return l10n.commodity_iron;
    case 'wool':
      return l10n.commodity_wool;
    case 'cotton':
      return l10n.commodity_cotton;
    case 'coal':
      return l10n.commodity_coal;
    case 'sugarCane':
      return l10n.commodity_sugarCane;
    case 'tobacco':
      return l10n.commodity_tobacco;
    case 'furs':
      return l10n.commodity_furs;
    case 'copper':
      return l10n.commodity_copper;
    case 'tin':
      return l10n.commodity_tin;
    case 'horses':
      return l10n.commodity_horses;
    case 'lumber':
      return l10n.commodity_lumber;
    case 'castIron':
      return l10n.commodity_castIron;
    case 'fabric':
      return l10n.commodity_fabric;
    case 'refinedSugar':
      return l10n.commodity_refinedSugar;
    case 'cigars':
      return l10n.commodity_cigars;
    case 'furHats':
      return l10n.commodity_furHats;
    case 'steel':
      return l10n.commodity_steel;
    case 'paper':
      return l10n.commodity_paper;
    case 'bronze':
      return l10n.commodity_bronze;
    case 'gold':
      return l10n.commodity_gold;
    case 'silver':
      return l10n.commodity_silver;
    case 'gems':
      return l10n.commodity_gems;
    case 'diamonds':
      return l10n.commodity_diamonds;
    case 'spices':
      return l10n.commodity_spices;
    default:
      return commodityId;
  }
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
    commodityDisplayName(l10n, commodityId),
    commodityCategoryDisplayName(l10n, commodity.category),
  );
}
