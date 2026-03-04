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
    this.highlightTileKey,
    this.highlightProvinceId,
    this.improvementLevelByTileKey,
  });

  final String regionId;
  final TileMapResult tileMap;
  final Game game;
  final int viewportWidth;
  final int viewportHeight;
  final int viewX;
  final int viewY;
  final MapGridLayer layer;
  /// Optional full tile key to highlight (regionId|provinceLocalId|x|y).
  final String? highlightTileKey;
  /// Optional full province id to highlight (regionId|provinceLocalId).
  final String? highlightProvinceId;
  /// Optional map of full tile key -> improvement level (> 0 indicates improved).
  final Map<String, int>? improvementLevelByTileKey;

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

    final layerLabel = switch (layer) {
      MapGridLayer.terrain => 'Terrain',
      MapGridLayer.political => 'Political',
      MapGridLayer.resources => 'Resources',
      MapGridLayer.units => 'Units',
    };

    final legend = _legendForLayer(layer);

    final grid = _buildHighlightedGrid(
      regionId: regionId,
      tileMap: tileMap,
      provincesById: provincesById,
      playerVisibilityByTile: playerVisibilityByTile,
      unitSymbolByTileKey: unitSymbolByTileKey,
    );

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
        // Render viewport as a colored grid, optionally highlighting a tile
        // or province and tinting improved tiles on the resources layer.
        grid,
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(legend, style: TextStyle(color: Colors.gray)),
        ),
      ],
    );
  }

  /// Render a colored grid where the highlighted tile is bright, tiles in the
  /// same province use normal color, and all other tiles are dimmed.
  Component _buildHighlightedGrid({
    required String regionId,
    required TileMapResult tileMap,
    required Map<String, Province> provincesById,
    required Map<String, String>? playerVisibilityByTile,
    required Map<String, String>? unitSymbolByTileKey,
  }) {
    final rows = <Component>[];

    final endX = (viewX + viewportWidth).clamp(0, tileMap.width);
    final endY = (viewY + viewportHeight).clamp(0, tileMap.height);
    final startX = viewX.clamp(0, tileMap.width);
    final startY = viewY.clamp(0, tileMap.height);

    for (var y = startY; y < endY; y++) {
      final cells = <Component>[];
      for (var x = startX; x < endX; x++) {
        final localId = tileMap.cell(x, y);
        final fullTileKey = makeFullTileKey(regionId, localId, x, y);
        final fullProvinceId = '$regionId|$localId';

        final visibility = getTileVisibility(fullTileKey, playerVisibilityByTile);
        final isVisible = visibility != TileVisibility.unexplored;

        String char = ' ';
        if (!isVisible) {
          char = '?';
        } else {
          final terrain = tileMap.terrainAt(x, y);
          switch (layer) {
            case MapGridLayer.terrain:
              char = terrainToChar(terrain);
              break;
            case MapGridLayer.political:
              final province = provincesById[fullProvinceId];
              final ownerId = province?.ownerId;
              final playerType = getPlayerType(ownerId, game.players);
              char = ownerToChar(ownerId, playerType);
              break;
            case MapGridLayer.resources:
              final resource = tileMap.resourceAt(x, y);
              char = resource != null ? resourceToChar(resource) : terrainToChar(terrain);
              break;
            case MapGridLayer.units:
              final unitChar = unitSymbolByTileKey?[fullTileKey];
              char = unitChar ?? terrainToChar(terrain);
              break;
          }
        }

        final isImproved = layer == MapGridLayer.resources &&
            isVisible &&
            (improvementLevelByTileKey?[fullTileKey] ?? 0) > 0;

        final color = tileColorFor(
          layer: layer,
          isImproved: isImproved,
          isHighlightedTile:
              highlightTileKey != null && fullTileKey == highlightTileKey,
          isHighlightedProvince: highlightProvinceId != null &&
              fullProvinceId == highlightProvinceId,
        );

        cells.add(Text(
          char,
          style: TextStyle(color: color),
        ));
      }
      rows.add(Row(children: cells));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
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
        return '?=unexplored ~sea .plains ♣forest ^hills ▲mt ≈swamp ▒desert '
            'g=grain m=meat w=wool h=horses t=timber i=iron c=copper n=tin k=coal '
            's=sugar b=tobac u=cottn f=furs p=spice v=silver G=gold e=gems d=diams empty=terrain '
            'imp>0=green(improved)';
      case MapGridLayer.units:
        return '?=unexplored Letter=unit type (1st letter); no letter=terrain';
    }
  }

  /// Determines the base color for a tile given its state and layer.
  static Color tileColorFor({
    required MapGridLayer layer,
    required bool isImproved,
    required bool isHighlightedTile,
    required bool isHighlightedProvince,
  }) {
    if (isHighlightedTile) {
      return Colors.yellow;
    }
    if (isHighlightedProvince) {
      return Colors.white;
    }
    if (layer == MapGridLayer.resources && isImproved) {
      return Colors.green;
    }
    return Colors.gray;
  }
}
