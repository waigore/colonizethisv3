import 'dart:ui' as ui;

import '../../../config/app_assets.dart';
import 'asset_image_cache.dart';

/// 64px fleet map marker; keep in sync with [FleetIconCache.assetPath].
const String kFleetMapIcon64PngAssetPath =
    '${kAppIcon64AssetPrefix}ui_icon_map_fleet.png';

const String _kFleetIconId = 'fleet';

class FleetIconCache extends AssetImageCache {
  static const double iconSize = 64.0;

  @override
  Iterable<String> get assetIds => const [_kFleetIconId];

  @override
  String assetPath(String assetId) => kFleetMapIcon64PngAssetPath;

  @override
  String get loadLogLabel => 'fleet map icon';

  ui.Image? getIcon() => imageForId(_kFleetIconId);
}

final fleetIconCache = FleetIconCache();
