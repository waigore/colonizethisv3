import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_catalog_loader.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_resolver.dart';
import 'package:colonizethis_app_fixtures/runtime/map_terrain_config.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  tearDown(() {
    MapThemeCatalogLoader.resetForTest();
    ActiveMapTheme.resetToDefaultsForTest();
    MapTerrainConfig.resetForTest();
  });

  group('MapThemeCatalog schema', () {
    test('parses bundled catalog with default theme per group', () async {
      await MapThemeCatalogLoader.ensureLoaded();
      final catalog = MapThemeCatalogLoader.instance;
      for (final group in MapThemeGroupId.values) {
        final def = catalog.requireDefault(group);
        expect(def.id, MapThemeGroupId.defaultThemeId);
      }
      final terrainDefault = catalog.requireDefault(MapThemeGroupId.terrain);
      expect(
        terrainDefault.tilesetConfig,
        MapTerrainConfig.kDefaultMapTerrainTilesetsAsset,
      );
      expect(
        terrainDefault.standaloneTilePrefix,
        kTerrainTileAssetPrefix,
      );
      final civilianDefault = catalog.requireDefault(
        MapThemeGroupId.civilianIcons,
      );
      expect(civilianDefault.iconPrefix, kAppIcon64AssetPrefix);
    });

    test('rejects missing default theme', () {
      expect(
        () => parseMapThemeCatalogJson('''
{
  "groups": {
    "terrain": {
      "themes": [{
        "id": "only",
        "name_l10n_key": "x",
        "tileset_config": "a.json",
        "standalone_tile_prefix": "p_"
      }]
    },
    "civilian_icons": {
      "themes": [{
        "id": "default",
        "name_l10n_key": "x",
        "icon_prefix": "assets/icons/64/"
      }]
    },
    "town_icons": {
      "themes": [{
        "id": "default",
        "name_l10n_key": "x",
        "icon_prefix": "assets/icons/64/"
      }]
    },
    "resource_icons": {
      "themes": [{
        "id": "default",
        "name_l10n_key": "x",
        "icon_prefix": "assets/icons/64/"
      }]
    },
    "fleet_icons": {
      "themes": [{
        "id": "default",
        "name_l10n_key": "x",
        "icon_prefix": "assets/icons/64/"
      }]
    },
    "province_label_icons": {
      "themes": [{
        "id": "default",
        "name_l10n_key": "x",
        "icon_prefix": "assets/icons/64/"
      }]
    }
  }
}
'''),
        throwsA(isA<FormatException>()),
      );
    });

    test('every declared theme has required assets in the bundle', () async {
      await MapThemeCatalogLoader.ensureLoaded();
      final catalog = MapThemeCatalogLoader.instance;
      for (final group in MapThemeGroupId.values) {
        for (final theme in catalog.themesFor(group)) {
          if (group == MapThemeGroupId.terrain) {
            final raw = await rootBundle.loadString(theme.tilesetConfig!);
            final cfgMap = jsonDecode(raw) as Map<String, dynamic>;
            for (final section in const [
              'wang_tilesets',
              'transport_tilesets',
            ]) {
              final entries = cfgMap[section]! as Map<String, dynamic>;
              for (final entry in entries.values) {
                final obj = entry! as Map<String, dynamic>;
                await rootBundle.loadString(obj['spec_json']! as String);
                await rootBundle.load(obj['atlas_png']! as String);
              }
            }
          } else if (group == MapThemeGroupId.civilianIcons) {
            for (final slug in kCivilianIconSlugs) {
              final path = '${theme.iconPrefix}ui_icon_civ_$slug.png';
              await rootBundle.load(path);
            }
          }
        }
      }
    });
  });

  group('resolveActiveMapTheme', () {
    test('empty settings resolve to default identity paths', () async {
      await MapThemeCatalogLoader.ensureLoaded();
      final theme = resolveActiveMapTheme(storedIds: const {});
      expect(theme.selectedId(MapThemeGroupId.terrain), 'default');
      expect(
        theme.terrainTilesetConfigPath,
        MapTerrainConfig.kDefaultMapTerrainTilesetsAsset,
      );
      expect(theme.terrainStandaloneTilePrefix, kTerrainTileAssetPrefix);
      expect(
        theme.iconPrefixFor(MapThemeGroupId.civilianIcons),
        kAppIcon64AssetPrefix,
      );
    });

    test('unknown stored id falls back to default', () async {
      await MapThemeCatalogLoader.ensureLoaded();
      final theme = resolveActiveMapTheme(
        storedIds: {
          MapThemeGroupId.terrain.settingsKey: 'missing_theme',
          MapThemeGroupId.civilianIcons.settingsKey: 'sepia',
        },
      );
      expect(theme.selectedId(MapThemeGroupId.terrain), 'default');
      expect(theme.selectedId(MapThemeGroupId.civilianIcons), 'sepia');
      expect(
        theme.iconPrefixFor(MapThemeGroupId.civilianIcons),
        'assets/themes/sepia/icons/64/',
      );
    });

    test('Hive persistence round-trips terrain theme selection', () async {
      final dir = await Directory.systemTemp.createTemp('ct_map_theme_');
      Hive.init(dir.path);
      await Hive.openBox<dynamic>(HiveBoxNames.settings);
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });

      await MapThemeCatalogLoader.ensureLoaded();
      final box = Hive.box<dynamic>(HiveBoxNames.settings);
      box.put(MapThemeGroupId.terrain.settingsKey, 'sepia');

      final theme = resolveActiveMapTheme();
      expect(theme.selectedId(MapThemeGroupId.terrain), 'sepia');
      expect(
        theme.terrainTilesetConfigPath,
        'assets/themes/sepia/data/map_terrain_tilesets.json',
      );
    });
  });

  group('ActiveMapTheme cache paths', () {
    test('civilian cache uses installed sepia prefix', () async {
      await MapThemeCatalogLoader.ensureLoaded();
      final theme = resolveActiveMapTheme(
        storedIds: {MapThemeGroupId.civilianIcons.settingsKey: 'sepia'},
      );
      ActiveMapTheme.install(theme);
      final cache = CivilianIconCache();
      for (final slug in kCivilianIconSlugs) {
        expect(
          cache.assetPath(slug),
          'assets/themes/sepia/icons/64/ui_icon_civ_$slug.png',
        );
      }
    });

    test('default ActiveMapTheme matches pre-theme identity', () {
      ActiveMapTheme.resetToDefaultsForTest();
      final cache = CivilianIconCache();
      expect(
        cache.assetPath('builder'),
        '${kAppIcon64AssetPrefix}ui_icon_civ_builder.png',
      );
    });

    test('sepia terrain install loads themed wang and transport atlases',
        () async {
      await MapThemeCatalogLoader.ensureLoaded();
      final theme = resolveActiveMapTheme(
        storedIds: {MapThemeGroupId.terrain.settingsKey: 'sepia'},
      );
      ActiveMapTheme.install(theme);
      await MapTerrainConfig.ensureLoaded(
        assetPath: ActiveMapTheme.current.terrainTilesetConfigPath,
      );
      expect(
        MapTerrainConfig.loadedAssetPath,
        'assets/themes/sepia/data/map_terrain_tilesets.json',
      );
      expect(
        MapTerrainConfig.instance.wangTilesets['sea_plains']!.atlasPngPath,
        'assets/themes/sepia/images/terrain/tilesets/tileset_sea_plains_v2_64.png',
      );
      expect(
        MapTerrainConfig.instance.transportTilesets['road']!.atlasPngPath,
        'assets/themes/sepia/images/terrain/tilesets/tileset_transport_road_64.png',
      );
    });

    test(
      'mid-session theme swap does not replace already-loaded MapTerrainConfig',
      () async {
        await MapThemeCatalogLoader.ensureLoaded();
        ActiveMapTheme.install(
          resolveActiveMapTheme(storedIds: const {}),
        );
        await MapTerrainConfig.ensureLoaded(
          assetPath: ActiveMapTheme.current.terrainTilesetConfigPath,
        );
        expect(
          MapTerrainConfig.loadedAssetPath,
          MapTerrainConfig.kDefaultMapTerrainTilesetsAsset,
        );

        ActiveMapTheme.install(
          resolveActiveMapTheme(
            storedIds: {MapThemeGroupId.terrain.settingsKey: 'sepia'},
          ),
        );
        await MapTerrainConfig.ensureLoaded(
          assetPath: ActiveMapTheme.current.terrainTilesetConfigPath,
        );
        expect(
          MapTerrainConfig.loadedAssetPath,
          MapTerrainConfig.kDefaultMapTerrainTilesetsAsset,
        );
        expect(
          MapTerrainConfig.instance.wangTilesets['sea_plains']!.atlasPngPath,
          'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.png',
        );
      },
    );
  });
}
