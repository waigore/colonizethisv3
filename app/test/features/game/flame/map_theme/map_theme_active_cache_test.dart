import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/active_map_theme.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_catalog_loader.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_models.dart';
import 'package:colonizethis_app/features/game/flame/map_theme/map_theme_resolver.dart';
import 'package:colonizethis_app_fixtures/runtime/map_terrain_config.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  tearDown(() {
    MapThemeCatalogLoader.resetForTest();
    ActiveMapTheme.resetToDefaultsForTest();
    MapTerrainConfig.resetForTest();
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

    test('sepia terrain install loads themed wang and transport atlases', () async {
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
      expect(
        theme.terrainStandaloneTilePrefix,
        'assets/themes/sepia/images/terrain/tile_',
      );
      expect(
        terrainTileAssetPath('hills'),
        'assets/themes/sepia/images/terrain/tile_hills.png',
      );
    });

    test(
      'mid-session theme swap does not replace already-loaded MapTerrainConfig',
      () async {
        await MapThemeCatalogLoader.ensureLoaded();
        ActiveMapTheme.install(resolveActiveMapTheme(storedIds: const {}));
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
