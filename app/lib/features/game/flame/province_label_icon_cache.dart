import 'dart:ui' as ui;

import '../../../config/app_assets.dart';
import 'asset_image_cache.dart';

const Set<String> kProvinceLabelIconIds = {
  'map_capital_star',
  'map_warp_zone',
  'map_presence_civilian',
  'map_presence_regiment',
  'map_presence_ship',
};

class ProvinceLabelIconCache extends AssetImageCache {
  static const double iconSize = 64.0;

  @override
  Iterable<String> get assetIds => kProvinceLabelIconIds;

  @override
  String assetPath(String assetId) =>
      '${kAppIcon64AssetPrefix}ui_icon_$assetId.png';

  @override
  String get loadLogLabel => 'province label icons';

  ui.Image? getIcon(String iconId) => imageForId(iconId);
}

final provinceLabelIconCache = ProvinceLabelIconCache();
