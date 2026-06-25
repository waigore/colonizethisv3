import 'dart:ui' as ui;

import '../../../config/app_assets.dart';
import 'asset_image_cache.dart';

const Set<String> kTownIconIds = {'port', 'town_inland_64'};

class TownIconCache extends AssetImageCache {
  static const String portIconId = 'port';
  static const String townIconId = 'town_inland_64';
  static const double portIconSize = 64.0;
  static const double townIconSize = 64.0;

  @override
  Iterable<String> get assetIds => kTownIconIds;

  @override
  String assetPath(String assetId) =>
      '${kAppIcon64AssetPrefix}ui_icon_com_$assetId.png';

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
}

final townIconCache = TownIconCache();
