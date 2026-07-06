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

  @override
  String assetPath(String assetId) {
    return assetPathForId(assetId);
  }

  /// Resolves bundle path for [assetId]. Tests may pass [useCandidateLevelOne]
  /// to override the compile-time [kCtNewTownIconsEnabled] gate.
  static String assetPathForId(
    String assetId, {
    bool? useCandidateLevelOne,
  }) {
    if (assetId == portIconId) {
      return '${kAppIcon64AssetPrefix}ui_icon_com_port.png';
    }
    final candidateLevelOne =
        useCandidateLevelOne ?? kCtNewTownIconsEnabled;
    if (candidateLevelOne && _isLevelOneTownIconId(assetId)) {
      return '${kAppIcon64AssetPrefix}ui_icon_com_${assetId}_candidate_64.png';
    }
    return '${kAppIcon64AssetPrefix}ui_icon_com_${assetId}_64.png';
  }

  static bool _isLevelOneTownIconId(String assetId) {
    for (final style in kTownIconStyles) {
      if (assetId == 'town_${style}_1') return true;
    }
    return false;
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
