import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app_fixtures/runtime/map_terrain_config.dart';
import 'package:flutter/foundation.dart';

/// Resolved per-group theme paths for the current process.
///
/// Installed once at app startup after Hive settings open. Flame caches read
/// [current] during `load()`. SPEC/program/map-theme-catalog.md.
@immutable
class ActiveMapTheme {
  const ActiveMapTheme({
    required this.selectedThemeIds,
    required this.terrainTilesetConfigPath,
    required this.terrainStandaloneTilePrefix,
    required this.iconPrefixes,
  });

  /// Selected theme id per group (after fallback).
  final Map<MapThemeGroupId, String> selectedThemeIds;

  final String terrainTilesetConfigPath;
  final String terrainStandaloneTilePrefix;

  /// Icon directory prefixes for non-terrain groups.
  final Map<MapThemeGroupId, String> iconPrefixes;

  /// Identity mapping matching pre-theme asset paths.
  static final ActiveMapTheme defaults = ActiveMapTheme(
    selectedThemeIds: {
      for (final g in MapThemeGroupId.values) g: MapThemeGroupId.defaultThemeId,
    },
    terrainTilesetConfigPath: MapTerrainConfig.kDefaultMapTerrainTilesetsAsset,
    terrainStandaloneTilePrefix: kTerrainTileAssetPrefix,
    iconPrefixes: {
      MapThemeGroupId.civilianIcons: kAppIcon64AssetPrefix,
      MapThemeGroupId.townIcons: kAppIcon64AssetPrefix,
      MapThemeGroupId.resourceIcons: kAppIcon64AssetPrefix,
      MapThemeGroupId.fleetIcons: kAppIcon64AssetPrefix,
      MapThemeGroupId.provinceLabelIcons: kAppIcon64AssetPrefix,
    },
  );

  static ActiveMapTheme _current = defaults;

  static ActiveMapTheme get current => _current;

  static void install(ActiveMapTheme theme) {
    _current = theme;
  }

  @visibleForTesting
  static void resetToDefaultsForTest() {
    _current = defaults;
  }

  String selectedId(MapThemeGroupId group) =>
      selectedThemeIds[group] ?? MapThemeGroupId.defaultThemeId;

  String iconPrefixFor(MapThemeGroupId group) {
    assert(group != MapThemeGroupId.terrain);
    return iconPrefixes[group] ?? kAppIcon64AssetPrefix;
  }
}
