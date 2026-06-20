import '../../../config/app_assets.dart';
import '../../../l10n/l10n.dart';

String eraRoman(int era) {
  const romans = ['I', 'II', 'III', 'IV'];
  return era >= 1 && era <= romans.length ? romans[era - 1] : '$era';
}

/// Tech-tree category, consolidating the per-category localized label and
/// bundled icon-asset mappings that were previously maintained as two parallel
/// `switch` statements over the same 8 category strings (#3279 target state
/// #7). [id] is the canonical catalog category string.
enum TechCategory {
  gathering('gathering', 'ui_icon_tech_gathering.png'),
  transport('transport', 'ui_icon_tech_transport.png'),
  labour('labour', 'ui_icon_tech_labour.png'),
  civilian('civilian', 'ui_icon_tech_civilian.png'),
  diplomacy('diplomacy', 'ui_icon_tech_diplomacy.png'),
  naval('naval', 'ui_icon_tech_naval.png'),
  military('military', 'ui_icon_tech_military.png'),
  newWorld('new-world', 'ui_icon_tech_new_world.png');

  const TechCategory(this.id, this._iconAssetFile);

  /// Canonical catalog category id (e.g. `gathering`, `new-world`).
  final String id;

  final String _iconAssetFile;

  /// Bundled asset path for the small category icon. Keeps the technology
  /// panel chip + slot icons consistent with the tech-tree node icons
  /// (SPEC/ui/technology-panel.md § Layout / wireframe;
  /// SPEC/ui/tech-tree-widget.md). Refs #2864 S2/S3.
  String get iconAsset => '$kAppIconAssetPrefix$_iconAssetFile';

  /// Localized display label for this category.
  String l10nLabel(AppLocalizations l10n) => switch (this) {
    TechCategory.gathering => l10n.techTree_categoryGathering,
    TechCategory.transport => l10n.techTree_categoryTransport,
    TechCategory.labour => l10n.techTree_categoryLabour,
    TechCategory.civilian => l10n.techTree_categoryCivilian,
    TechCategory.diplomacy => l10n.techTree_categoryDiplomacy,
    TechCategory.naval => l10n.techTree_categoryNaval,
    TechCategory.military => l10n.techTree_categoryMilitary,
    TechCategory.newWorld => l10n.techTree_categoryNewWorld,
  };

  /// Resolves a catalog category [id] to its [TechCategory], or `null` when the
  /// id is unknown.
  static TechCategory? fromId(String? id) {
    for (final category in TechCategory.values) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}

String techCategoryLabelL10n(AppLocalizations l10n, String category) {
  return TechCategory.fromId(category)?.l10nLabel(l10n) ?? category;
}

/// Bundled asset path for the small icon associated with a tech [category],
/// or `null` when no icon is registered for the category id.
String? techCategoryIconAssetPath(String? category) {
  return TechCategory.fromId(category)?.iconAsset;
}
