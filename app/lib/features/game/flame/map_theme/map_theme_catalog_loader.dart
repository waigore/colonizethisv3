import 'dart:convert';

import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final _log = packageLogger('map');

/// Loads and memoizes [MapThemeCatalog] from the bundled manifest.
class MapThemeCatalogLoader {
  MapThemeCatalogLoader._();

  static MapThemeCatalog? _instance;

  static MapThemeCatalog get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'MapThemeCatalog not loaded; call MapThemeCatalogLoader.ensureLoaded()',
      );
    }
    return i;
  }

  static bool get isLoaded => _instance != null;

  static Future<void> ensureLoaded({
    String assetPath = MapThemeCatalog.assetPath,
  }) async {
    if (_instance != null) return;
    _log.d('map: loading theme catalog from $assetPath');
    final raw = await rootBundle.loadString(assetPath);
    _instance = parseMapThemeCatalogJson(raw);
    _log.i(
      'map: theme catalog loaded groups=${_instance!.themesByGroup.length}',
    );
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  @visibleForTesting
  static void installForTest(MapThemeCatalog catalog) {
    _instance = catalog;
  }
}

/// Parses and schema-validates catalog JSON. Throws [FormatException] on errors.
MapThemeCatalog parseMapThemeCatalogJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('map_themes.json: root must be an object');
  }
  final groupsRaw = decoded['groups'];
  if (groupsRaw is! Map<String, dynamic>) {
    throw const FormatException('map_themes.json: groups must be an object');
  }

  final themesByGroup = <MapThemeGroupId, List<MapThemeEntry>>{};
  for (final groupId in MapThemeGroupId.values) {
    final groupRaw = groupsRaw[groupId.catalogId];
    if (groupRaw is! Map<String, dynamic>) {
      throw FormatException(
        'map_themes.json: missing groups.${groupId.catalogId} object',
      );
    }
    final themesRaw = groupRaw['themes'];
    if (themesRaw is! List<dynamic> || themesRaw.isEmpty) {
      throw FormatException(
        'map_themes.json: groups.${groupId.catalogId}.themes must be a non-empty list',
      );
    }
    final themes = <MapThemeEntry>[];
    for (final item in themesRaw) {
      if (item is! Map<String, dynamic>) {
        throw FormatException(
          'map_themes.json: groups.${groupId.catalogId}.themes entries must be objects',
        );
      }
      themes.add(_parseThemeEntry(groupId, item));
    }
    final hasDefault = themes.any((t) => t.id == MapThemeGroupId.defaultThemeId);
    if (!hasDefault) {
      throw FormatException(
        'map_themes.json: groups.${groupId.catalogId} missing default theme',
      );
    }
    themesByGroup[groupId] = themes;
  }

  for (final key in groupsRaw.keys) {
    if (MapThemeGroupId.tryParse(key) == null) {
      throw FormatException('map_themes.json: unknown group id "$key"');
    }
  }

  return MapThemeCatalog(themesByGroup: themesByGroup);
}

MapThemeEntry _parseThemeEntry(
  MapThemeGroupId group,
  Map<String, dynamic> json,
) {
  final id = json['id'];
  final nameKey = json['name_l10n_key'];
  if (id is! String || id.isEmpty) {
    throw FormatException(
      'map_themes.json: groups.${group.catalogId} theme id must be non-empty string',
    );
  }
  if (nameKey is! String || nameKey.isEmpty) {
    throw FormatException(
      'map_themes.json: groups.${group.catalogId} theme $id name_l10n_key required',
    );
  }

  if (group == MapThemeGroupId.terrain) {
    final tileset = json['tileset_config'];
    final prefix = json['standalone_tile_prefix'];
    if (tileset is! String || tileset.isEmpty) {
      throw FormatException(
        'map_themes.json: terrain theme $id tileset_config required',
      );
    }
    if (prefix is! String || prefix.isEmpty) {
      throw FormatException(
        'map_themes.json: terrain theme $id standalone_tile_prefix required',
      );
    }
    return MapThemeEntry(
      id: id,
      nameL10nKey: nameKey,
      tilesetConfig: tileset,
      standaloneTilePrefix: prefix,
    );
  }

  final iconPrefix = json['icon_prefix'];
  if (iconPrefix is! String || iconPrefix.isEmpty) {
    throw FormatException(
      'map_themes.json: groups.${group.catalogId} theme $id icon_prefix required',
    );
  }
  return MapThemeEntry(
    id: id,
    nameL10nKey: nameKey,
    iconPrefix: iconPrefix,
  );
}
