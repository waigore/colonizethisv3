import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_catalog_loader.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:hive/hive.dart';

final _log = packageLogger('map');

/// Reads Hive settings (or [storedIds]) and builds [ActiveMapTheme] against
/// the loaded catalog. Unknown ids fall back to `default` with a warning.
ActiveMapTheme resolveActiveMapTheme({
  MapThemeCatalog? catalog,
  Map<String, Object?>? storedIds,
}) {
  final cat = catalog ?? MapThemeCatalogLoader.instance;
  final stored = storedIds ?? _readStoredThemeIds();

  final selected = <MapThemeGroupId, String>{};
  for (final group in MapThemeGroupId.values) {
    final raw = stored[group.settingsKey];
    final requested = raw is String && raw.isNotEmpty
        ? raw
        : MapThemeGroupId.defaultThemeId;
    final entry = cat.themeById(group, requested);
    if (entry == null) {
      _log.w(
        'map: unknown theme id "$requested" for ${group.catalogId}; '
        'falling back to default',
      );
      selected[group] = MapThemeGroupId.defaultThemeId;
    } else {
      selected[group] = entry.id;
    }
  }

  final terrainEntry = cat.themeById(
    MapThemeGroupId.terrain,
    selected[MapThemeGroupId.terrain]!,
  )!;
  final iconPrefixes = <MapThemeGroupId, String>{};
  for (final group in MapThemeGroupId.values) {
    if (group == MapThemeGroupId.terrain) continue;
    final entry = cat.themeById(group, selected[group]!)!;
    iconPrefixes[group] = entry.iconPrefix!;
  }

  return ActiveMapTheme(
    selectedThemeIds: selected,
    terrainTilesetConfigPath: terrainEntry.tilesetConfig!,
    terrainStandaloneTilePrefix: terrainEntry.standaloneTilePrefix!,
    iconPrefixes: iconPrefixes,
  );
}

Map<String, Object?> _readStoredThemeIds() {
  if (!Hive.isBoxOpen(HiveBoxNames.settings)) {
    return const {};
  }
  final box = Hive.box<dynamic>(HiveBoxNames.settings);
  final out = <String, Object?>{};
  for (final group in MapThemeGroupId.values) {
    out[group.settingsKey] = box.get(group.settingsKey);
  }
  return out;
}

/// Loads catalog (if needed), resolves from Hive, and installs [ActiveMapTheme].
Future<ActiveMapTheme> loadAndInstallActiveMapTheme() async {
  await MapThemeCatalogLoader.ensureLoaded();
  final theme = resolveActiveMapTheme();
  ActiveMapTheme.install(theme);
  return theme;
}
