// Map grid widget for in-game shell: ASCII viewport with layer switching and scroll.
// SPEC/tui/screens/in-game-shell.md § Map Grid Widget.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:nocterm/nocterm.dart';

import 'package:ctterm/map_tui_mapping.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Map grid widget showing a viewport of the region tile map with layer switching (terrain, political, resources, units) and scroll.
/// Scroll offset and layer are controlled by the parent (in-game shell) so the shell can share key handling with the topology graph.
class MapGridWidget extends StatelessComponent {
  const MapGridWidget({
    super.key,
    required this.regionId,
    required this.tileMap,
    required this.game,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.viewX,
    required this.viewY,
    required this.layer,
  });

  final String regionId;
  final TileMapResult tileMap;
  final Game game;
  final int viewportWidth;
  final int viewportHeight;
  final int viewX;
  final int viewY;
  final MapGridLayer layer;

  /// Builds map from full tile key to unit symbol for the units layer.
  static Map<String, String> buildUnitSymbolByTileKey(
    Game game,
    String regionId,
  ) {
    final units = regionId == 'oldWorld'
        ? game.worldState.oldWorld.units
        : game.worldState.newWorld.units;
    final tileKeysByProv = game.worldState.tileKeysByRegionAndProvince;
    final regionTiles = tileKeysByProv[regionId];
    final result = <String, String>{};

    for (final unit in units) {
      String? tileKey;
      if (unit.tileKey != null && unit.tileKey!.isNotEmpty) {
        tileKey = unit.tileKey;
      } else if (regionTiles != null) {
        final provTiles = regionTiles[unit.locationProvinceId];
        tileKey = provTiles?.isNotEmpty == true ? provTiles!.first : null;
      }
      if (tileKey != null) {
        final symbol = unit.type.isNotEmpty ? unit.type.substring(0, 1).toUpperCase() : 'U';
        result[tileKey] = symbol;
      }
    }
    return result;
  }

  @override
  Component build(BuildContext context) {
    final game = this.game;
    final tileMap = this.tileMap;
    final regionId = this.regionId;
    final provinces = regionId == 'oldWorld'
        ? game.worldState.oldWorld.provinces
        : game.worldState.newWorld.provinces;
    final provincesById = buildProvincesMap(provinces);
    String? humanPlayerId;
    for (final entry in game.aiControlByGpId.entries) {
      if (!entry.value) {
        humanPlayerId = entry.key;
        break;
      }
    }
    final playerVisibilityByTile = humanPlayerId != null
        ? game.worldState.playerVisibilityByTile[humanPlayerId]
        : null;
    final capitalTiles = getCapitalTiles(game);
    final portTiles = getPortTiles(game.worldState);
    final unitSymbolByTileKey = layer == MapGridLayer.units
        ? buildUnitSymbolByTileKey(game, regionId)
        : null;

    final lines = renderRegionMapViewport(
      regionId: regionId,
      tileMap: tileMap,
      provincesById: provincesById,
      playerVisibilityByTile: playerVisibilityByTile,
      players: game.players,
      capitalTiles: capitalTiles,
      portTiles: portTiles,
      offsetX: viewX,
      offsetY: viewY,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      layer: layer,
      unitSymbolByTileKey: unitSymbolByTileKey,
    );

    final layerLabel = switch (layer) {
      MapGridLayer.terrain => 'Terrain',
      MapGridLayer.political => 'Political',
      MapGridLayer.resources => 'Resources',
      MapGridLayer.units => 'Units',
    };

    final legend = _legendForLayer(layer);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
              'Map [Layer: $layerLabel]  [ ]=layer (scroll follows province)',
              style: TextStyle(color: Colors.cyan),
            ),
        ),
        ...lines.map((line) => Text(line)),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(legend, style: TextStyle(color: Colors.gray)),
        ),
      ],
    );
  }

  /// One-line legend for the current layer to disambiguate symbols.
  static String _legendForLayer(MapGridLayer layer) {
    switch (layer) {
      case MapGridLayer.terrain:
        return '?=unexplored ~sea .plains ♣forest ^hills ▲mt ≈swamp ▒desert';
      case MapGridLayer.political:
        return '?=unexplored ·unclaimed A–Z=GP mX=minor tX=tribe';
      case MapGridLayer.resources:
        return '?=unexplored g=gra m=meat w=wool h=horse t=timber i=iron c=copper k=coal G=gold … (empty=terrain)';
      case MapGridLayer.units:
        return '?=unexplored Letter=unit type (1st letter); no letter=terrain';
    }
  }
}
