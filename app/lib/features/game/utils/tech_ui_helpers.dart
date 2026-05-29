import '../../../config/app_assets.dart';
import '../../../l10n/l10n.dart';

String eraRoman(int era) {
  const romans = ['I', 'II', 'III', 'IV'];
  return era >= 1 && era <= romans.length ? romans[era - 1] : '$era';
}

String techCategoryLabelL10n(AppLocalizations l10n, String category) {
  return switch (category) {
    'gathering' => l10n.techTree_categoryGathering,
    'transport' => l10n.techTree_categoryTransport,
    'labour' => l10n.techTree_categoryLabour,
    'civilian' => l10n.techTree_categoryCivilian,
    'diplomacy' => l10n.techTree_categoryDiplomacy,
    'naval' => l10n.techTree_categoryNaval,
    'military' => l10n.techTree_categoryMilitary,
    'new-world' => l10n.techTree_categoryNewWorld,
    _ => category,
  };
}

/// Bundled asset path for the small icon associated with a tech [category],
/// or `null` when no icon is registered for the category id.
///
/// Mirrors the per-category icon map used by the tech-tree widget. Sourcing
/// this from a shared helper keeps the technology panel chip + slot icons
/// consistent with the tech-tree node icons (SPEC/ui/technology-panel.md
/// § Layout / wireframe; SPEC/ui/tech-tree-widget.md). Refs #2864 S2/S3.
String? techCategoryIconAssetPath(String? category) {
  switch (category) {
    case 'gathering':
      return '${kAppIconAssetPrefix}ui_icon_tech_gathering.png';
    case 'new-world':
      return '${kAppIconAssetPrefix}ui_icon_tech_new_world.png';
    case 'transport':
      return '${kAppIconAssetPrefix}ui_icon_tech_transport.png';
    case 'labour':
      return '${kAppIconAssetPrefix}ui_icon_tech_labour.png';
    case 'civilian':
      return '${kAppIconAssetPrefix}ui_icon_tech_civilian.png';
    case 'diplomacy':
      return '${kAppIconAssetPrefix}ui_icon_tech_diplomacy.png';
    case 'naval':
      return '${kAppIconAssetPrefix}ui_icon_tech_naval.png';
    case 'military':
      return '${kAppIconAssetPrefix}ui_icon_tech_military.png';
    default:
      return null;
  }
}
