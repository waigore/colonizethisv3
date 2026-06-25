import 'dart:ui' as ui;

import '../../../config/app_assets.dart';
import 'asset_image_cache.dart';

/// Resource IDs for which icons exist (excludes commodities without tile resources).
const Set<String> kResourceIconIds = {
  'grain',
  'meat',
  'timber',
  'iron',
  'wool',
  'cotton',
  'coal',
  'sugar_cane',
  'tobacco',
  'furs',
  'copper',
  'tin',
  'horses',
  'lumber',
  'cast_iron',
  'fabric',
  'refined_sugar',
  'cigars',
  'fur_hats',
  'steel',
  'paper',
  'bronze',
  'gold',
  'silver',
  'gems',
  'diamonds',
  'spices',
};

/// Cache for loaded resource icons.
/// Loads all resource icons at startup and stores them keyed by resource ID.
class ResourceIconCache extends AssetImageCache {
  /// Edge length of resource icon **source** PNG assets in pixels (on-map display
  /// size is defined in SPEC/ui/map-widget.md § Resource Icons).
  static const double iconSize = 64.0;

  @override
  Iterable<String> get assetIds => kResourceIconIds;

  @override
  String assetPath(String assetId) =>
      '${kAppIcon64AssetPrefix}ui_icon_com_$assetId.png';

  @override
  String get loadLogLabel => 'resource icons';

  /// Returns the icon image for the given resource ID, or null if not loaded.
  ui.Image? getIcon(String? resourceId) {
    if (resourceId == null || resourceId.isEmpty) return null;
    return imageForId(resourceId);
  }

  /// Returns true if an icon exists for the given resource ID.
  bool hasIcon(String? resourceId) {
    if (resourceId == null || resourceId.isEmpty) return false;
    return hasImageForId(resourceId);
  }
}

/// Global resource icon cache instance.
final resourceIconCache = ResourceIconCache();
