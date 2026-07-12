import 'package:colonizethis_app_l10n/l10n/l10n.dart';

/// Localized display name for [commodityId] from `AppLocalizations`.
///
/// Falls back to the raw id when the commodity is not in the catalog / has no
/// `commodity_<id>` key. UI paths must use this helper rather than
/// `CommodityCatalog.displayName` (Refs #3987).
///
/// Lives under `app/lib/widgets/` so shared widgets (e.g. [ResourceLabelInline])
/// can resolve names without importing `features/` (`repo.app_widget_imports`).
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
