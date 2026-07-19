import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';

import '../../../../config/app_assets.dart';
import '../../../../config/ct_legacy_town_icons.dart';
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

  /// On-map destination side (px) by level (Refs #3870 S10): 48/56/60/64.
  /// Ports use [portIconSize] and ignore this ladder.
  static double townIconDestinationSize(int townDevelopmentLevel) =>
      const <double>[48, 56, 60, 64][townDevelopmentLevel.clamp(1, 4) - 1];

  @override
  Iterable<String> get assetIds => kTownIconIds;

  @override
  String assetPath(String assetId) {
    return assetPathForId(assetId);
  }

  /// Resolves bundle path for [assetId]. Tests may pass [useLegacyTownIcons]
  /// to override the compile-time [kCtLegacyTownIconsEnabled] gate.
  static String assetPathForId(
    String assetId, {
    bool? useLegacyTownIcons,
    String? iconPrefix,
  }) {
    final prefix =
        iconPrefix ??
        ActiveMapTheme.current.iconPrefixFor(MapThemeGroupId.townIcons);
    if (assetId == portIconId) {
      return '${prefix}ui_icon_com_port.png';
    }
    final useLegacy = useLegacyTownIcons ?? kCtLegacyTownIconsEnabled;
    if (useLegacy && _isLevel1TownIconId(assetId)) {
      final suffix = assetId.replaceFirst('town_', '');
      return '${prefix}ui_icon_com_town_${suffix}_legacy_64.png';
    }
    return '${prefix}ui_icon_com_${assetId}_64.png';
  }

  static bool _isLevel1TownIconId(String assetId) {
    for (final style in kTownIconStyles) {
      if (assetId == 'town_${style}_1') return true;
    }
    return false;
  }

  /// Retired S9a level-1 hamlet PNGs shipped for rollback via
  /// [CT_LEGACY_TOWN_ICONS].
  static Iterable<String> get legacyTownIconAssetPaths sync* {
    for (final style in kTownIconStyles) {
      yield assetPathForId(
        'town_${style}_1',
        useLegacyTownIcons: true,
      );
    }
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
