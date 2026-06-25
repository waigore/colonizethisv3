import 'dart:ui' as ui;

import '../../../config/app_assets.dart';
import 'asset_image_cache.dart';

const Map<String, String> kCivilianTypeToIconSlug = {
  'builder': 'builder',
  'engineer': 'engineer',
  'rail builder': 'rail_builder',
  'rail_builder': 'rail_builder',
  'railbuilder': 'rail_builder',
  'explorer': 'explorer',
  'merchant': 'merchant',
  'spy': 'spy',
};

const Set<String> kCivilianIconSlugs = {
  'builder',
  'engineer',
  'rail_builder',
  'explorer',
  'merchant',
  'spy',
};

class CivilianIconCache extends AssetImageCache {
  static const double iconSize = 64.0;

  @override
  Iterable<String> get assetIds => kCivilianIconSlugs;

  @override
  String assetPath(String assetId) =>
      '${kAppIcon64AssetPrefix}ui_icon_civ_$assetId.png';

  @override
  String get loadLogLabel => 'civilian map icons';

  String? _normalizeSlug(String unitType) {
    final normalized = unitType.trim().toLowerCase();
    return kCivilianTypeToIconSlug[normalized];
  }

  ui.Image? getIcon({required String unitType, required bool grayscale}) {
    // `grayscale` is handled at paint-time in the renderer so we keep only
    // one decoded asset per civilian type in cache.
    final _ = grayscale;
    final slug = _normalizeSlug(unitType);
    if (slug == null) return null;
    return imageForId(slug);
  }
}

final civilianIconCache = CivilianIconCache();
