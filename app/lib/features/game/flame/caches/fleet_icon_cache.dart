import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';

import '../../../../config/app_assets.dart';
import 'asset_image_cache.dart';

/// 64px fleet map marker default path; keep in sync with default theme prefix.
const String kFleetMapIcon64PngAssetPath =
    '${kAppIcon64AssetPrefix}ui_icon_map_fleet.png';

const String _kFleetIconId = 'fleet';

class FleetIconCache extends AssetImageCache {
  static const double iconSize = 64.0;

  @override
  Iterable<String> get assetIds => const [_kFleetIconId];

  @override
  String assetPath(String assetId) =>
      '${ActiveMapTheme.current.iconPrefixFor(MapThemeGroupId.fleetIcons)}'
      'ui_icon_map_fleet.png';

  @override
  String get loadLogLabel => 'fleet map icon';

  ui.Image? getIcon() => imageForId(_kFleetIconId);
}

final fleetIconCache = FleetIconCache();
