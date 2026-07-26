import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:flutter/material.dart';

/// Civilian unit type icon for Flutter chrome (panels, dialogs).
/// Uses the same asset slugs as [CivilianIconCache] on the map.
class CivilianUnitTypeIcon extends StatelessWidget {
  const CivilianUnitTypeIcon({
    super.key,
    required this.unitType,
    this.size = 20,
  });

  final String unitType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = unitType.trim().toLowerCase();
    final slug = kCivilianTypeToIconSlug[normalized];
    if (slug == null) {
      return SizedBox(width: size, height: size);
    }
    final path =
        '${ActiveMapTheme.current.iconPrefixFor(MapThemeGroupId.civilianIcons)}'
        'ui_icon_civ_$slug.png';
    return StrictAssetIcon(assetPath: path, width: size, height: size);
  }
}
