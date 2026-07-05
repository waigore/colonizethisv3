import 'dart:ui' as ui;

import '../../../../config/app_assets.dart';
import '../../../../config/ct_new_town_icons.dart';
import 'asset_image_cache.dart';

/// All town icon cache ids: 16 level/style variants plus the port glyph.
const Set<String> kTownIconStyles = {
  kTownIconStyleEuro,
  kTownIconStyleColonial,
  kTownIconStyleTribal,
};

const Set<int> kTownDevelopmentLevels = {1, 2, 3, 4};

/// Style ids re-exported for app tests (canonical source: colonizethis_map).
const String kTownIconStyleEuro = 'euro';
const String kTownIconStyleColonial = 'colonial';
const String kTownIconStyleTribal = 'tribal';

Set<String> buildTownIconAssetIds() {
  final ids = <String>{TownIconCache.portIconId};
  for (final style in kTownIconStyles) {
    for (final level in kTownDevelopmentLevels) {
      ids.add('town_${style}_$level');
    }
  }
  return ids;
}

final Set<String> kTownIconIds = buildTownIconAssetIds();

class TownIconCache extends AssetImageCache {
  static const String portIconId = 'port';
  static const double portIconSize = 64.0;
  static const double townIconSize = 64.0;

  @override
  Iterable<String> get assetIds => kTownIconIds;

  /// Whether [assetId] is a level-1 town glyph (`town_{style}_1`).
  static bool isLevelOneTownIconId(String assetId) {
    return assetId.startsWith('town_') && assetId.endsWith('_1');
  }

  /// Resolves the 64×64 asset file name for a town/port cache id.
  ///
  /// When [useNewTownIcons] is true, level-1 ids load S9b candidate PNGs
  /// (`ui_icon_com_town_{style}_1_candidate_64.png`); levels 2–4 are unchanged.
  static String townIconAssetFileName(
    String assetId, {
    bool useNewTownIcons = kCtNewTownIconsEnabled,
  }) {
    if (assetId == portIconId) {
      return 'ui_icon_com_port.png';
    }
    if (useNewTownIcons && isLevelOneTownIconId(assetId)) {
      return 'ui_icon_com_${assetId}_candidate_64.png';
    }
    return 'ui_icon_com_${assetId}_64.png';
  }

  @override
  String assetPath(String assetId) {
    return '${kAppIcon64AssetPrefix}${townIconAssetFileName(assetId)}';
  }

  @override
  String get loadLogLabel => 'town/port icons';

  ui.Image? getIcon(String? iconId) {
    if (iconId == null || iconId.isEmpty) return null;
    return imageForId(iconId);
  }

  bool hasIcon(String? iconId) {
    if (iconId == null || iconId.isEmpty) return false;
    return hasImageForId(iconId);
  }

  /// Resolves the cache id for a [TownMarkerView] town glyph.
  static String townIconIdForMarker({
    required String townIconStyle,
    required int townDevelopmentLevel,
  }) {
    final level = townDevelopmentLevel.clamp(1, 4);
    return 'town_${townIconStyle}_$level';
  }
}

final townIconCache = TownIconCache();
