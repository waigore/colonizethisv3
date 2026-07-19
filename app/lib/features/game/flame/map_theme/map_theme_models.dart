import 'package:flutter/foundation.dart';

/// Theme group ids matching `assets/data/map_themes.json` and Flame cache
/// boundaries. SPEC/program/map-theme-catalog.md.
enum MapThemeGroupId {
  terrain('terrain', 'mapTheme.terrain'),
  civilianIcons('civilian_icons', 'mapTheme.civilianIcons'),
  townIcons('town_icons', 'mapTheme.townIcons'),
  resourceIcons('resource_icons', 'mapTheme.resourceIcons'),
  fleetIcons('fleet_icons', 'mapTheme.fleetIcons'),
  provinceLabelIcons('province_label_icons', 'mapTheme.provinceLabelIcons');

  const MapThemeGroupId(this.catalogId, this.settingsKey);

  /// Manifest group key.
  final String catalogId;

  /// Hive `settings` box key for the selected theme id.
  final String settingsKey;

  static const String defaultThemeId = 'default';

  static MapThemeGroupId? tryParse(String catalogId) {
    for (final g in MapThemeGroupId.values) {
      if (g.catalogId == catalogId) return g;
    }
    return null;
  }
}

/// One theme entry under a catalog group.
@immutable
class MapThemeEntry {
  const MapThemeEntry({
    required this.id,
    required this.nameL10nKey,
    this.tilesetConfig,
    this.standaloneTilePrefix,
    this.iconPrefix,
  });

  final String id;
  final String nameL10nKey;

  /// Terrain only: path to tileset config JSON.
  final String? tilesetConfig;

  /// Terrain only: prefix before `<stem>.png` for standalone tiles.
  final String? standaloneTilePrefix;

  /// Icon groups only: directory prefix before icon filename.
  final String? iconPrefix;
}

/// Validated theme catalog loaded from `assets/data/map_themes.json`.
@immutable
class MapThemeCatalog {
  const MapThemeCatalog({required this.themesByGroup});

  final Map<MapThemeGroupId, List<MapThemeEntry>> themesByGroup;

  static const String assetPath = 'assets/data/map_themes.json';

  List<MapThemeEntry> themesFor(MapThemeGroupId group) =>
      themesByGroup[group] ?? const [];

  MapThemeEntry? themeById(MapThemeGroupId group, String id) {
    for (final t in themesFor(group)) {
      if (t.id == id) return t;
    }
    return null;
  }

  MapThemeEntry requireDefault(MapThemeGroupId group) {
    final d = themeById(group, MapThemeGroupId.defaultThemeId);
    if (d == null) {
      throw StateError(
        'map_themes.json: group ${group.catalogId} missing default theme',
      );
    }
    return d;
  }

  /// Groups that have more than one bundled theme (Settings pickers).
  Iterable<MapThemeGroupId> get multiThemeGroups sync* {
    for (final g in MapThemeGroupId.values) {
      if (themesFor(g).length > 1) yield g;
    }
  }
}
