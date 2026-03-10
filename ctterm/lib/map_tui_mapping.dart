// Map TUI mapping: converts game map data to ASCII/Unicode terminal display.
// SPEC/tui/map-tui-mapping.md

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'map_keys.dart';
import 'map_symbols.dart';
import 'tile_visibility.dart';

export 'map_keys.dart';
export 'map_symbols.dart';
export 'tile_visibility.dart';

/// Map grid display layer for the in-game shell map grid widget. SPEC/tui/screens/in-game-shell.md.
enum MapGridLayer {
  terrain,
  political,
  resources,
  units,
}

/// Renders a single tile for display.
/// Returns a tuple: [character, isFogged, isCapital, isPort]
({String char, bool fogged, bool capital, bool port}) getTileDisplay({
  required TileMapResult tileMap,
  required int x,
  required int y,
  required String tileKey,
  required Map<String, Province> provincesById,
  required Map<String, String>? playerVisibilityByTile,
  required List<Player> players,
  required Set<String> capitalTiles,
  required Set<String> portTiles,
  bool showTerrain = true,
  bool showOwnership = true,
}) {
  final visibility = getTileVisibility(tileKey, playerVisibilityByTile);
  final isFogged = visibility == TileVisibility.fogged;
  final isRevealed = visibility == TileVisibility.revealed;
  final isFullyVisible = visibility == TileVisibility.fullyVisible;
  final isVisible = isFogged || isRevealed || isFullyVisible;

  // Get terrain character
  String char = ' ';
  if (showTerrain) {
    final terrain = tileMap.terrainAt(x, y);
    char = terrainToChar(terrain);
  }

  // Get province info if visible
  String? ownerId;
  bool isCapital = false;
  bool isPort = false;

  if (isVisible) {
    final regionId = getTileRegionId(tileMap, x, y);
    if (regionId != null) {
      // Find province by region ID
      final province = provincesById[regionId];
      if (province != null) {
        ownerId = province.ownerId;
        isCapital = capitalTiles.contains(tileKey);
        isPort = portTiles.contains(tileKey);

        // Add owner prefix if showing ownership
        if (showOwnership && ownerId != null) {
          final playerType = getPlayerType(ownerId, players);
          final ownerChar = ownerToChar(ownerId, playerType);
          char = ownerChar;
        }
      }
    }
  } else {
    // Unexplored - show space
    char = ' ';
  }

  return (
    char: char,
    fogged: isFogged,
    capital: isCapital,
    port: isPort,
  );
}

/// Renders an entire region map to ASCII art.
/// Returns list of lines representing the map.
List<String> renderRegionMap({
  required TileMapResult tileMap,
  required Map<String, Province> provincesById,
  required Map<String, String>? playerVisibilityByTile,
  required List<Player> players,
  required Set<String> capitalTiles,
  required Set<String> portTiles,
  bool showTerrain = true,
  bool showOwnership = true,
  int? maxWidth,
  int? maxHeight,
}) {
  final lines = <String>[];

  // Calculate render bounds
  final width =
      maxWidth != null && maxWidth < tileMap.width ? maxWidth : tileMap.width;
  final height = maxHeight != null && maxHeight < tileMap.height
      ? maxHeight
      : tileMap.height;

  for (var y = 0; y < height; y++) {
    final buffer = StringBuffer();

    for (var x = 0; x < width; x++) {
      final tileKey = makeTileKey(tileMap.cell(x, y), x, y);

      final tile = getTileDisplay(
        tileMap: tileMap,
        x: x,
        y: y,
        tileKey: tileKey,
        provincesById: provincesById,
        playerVisibilityByTile: playerVisibilityByTile,
        players: players,
        capitalTiles: capitalTiles,
        portTiles: portTiles,
        showTerrain: showTerrain,
        showOwnership: showOwnership,
      );

      // Build display character with markers
      String displayChar = tile.char;

      // Add capital marker
      if (tile.capital && tile.char != ' ') {
        displayChar = '${tile.char}*';
      }

      // Add port marker
      if (tile.port && tile.char != ' ') {
        displayChar = '${tile.char}¶';
      }

      // Pad to 2 characters for alignment
      if (displayChar.length == 1) {
        displayChar = '$displayChar ';
      }

      buffer.write(displayChar);
    }

    lines.add(buffer.toString());
  }

  return lines;
}

/// Renders a viewport of the region map for the in-game shell map grid widget.
/// [offsetX], [offsetY] are the top-left cell of the viewport; [viewportWidth] and
/// [viewportHeight] are the visible size.
/// [layer] selects which layer to display (terrain, political, resources, units).
/// [unitSymbolByTileKey] maps full tile key (regionId|localId|x|y) to a character
/// for the units layer; only used when [layer] is [MapGridLayer.units].
/// Visibility is from [playerVisibilityByTile] (game setup gives the human player
/// visibility of their own provinces).
/// Returns one line per viewport row; each line is one character per column (no padding).
List<String> renderRegionMapViewport({
  required String regionId,
  required TileMapResult tileMap,
  required Map<String, Province> provincesById,
  required Map<String, String>? playerVisibilityByTile,
  required List<Player> players,
  required Set<String> capitalTiles,
  required Set<String> portTiles,
  required int offsetX,
  required int offsetY,
  required int viewportWidth,
  required int viewportHeight,
  required MapGridLayer layer,
  Map<String, String>? unitSymbolByTileKey,
}) {
  final lines = <String>[];
  final endX = (offsetX + viewportWidth).clamp(0, tileMap.width);
  final endY = (offsetY + viewportHeight).clamp(0, tileMap.height);
  final startX = offsetX.clamp(0, tileMap.width);
  final startY = offsetY.clamp(0, tileMap.height);

  for (var y = startY; y < endY; y++) {
    final buffer = StringBuffer();
    for (var x = startX; x < endX; x++) {
      final localId = tileMap.cell(x, y);
      final fullTileKey = makeFullTileKey(regionId, localId, x, y);
      final fullProvinceId = '$regionId|$localId';
      final visibility = getTileVisibility(fullTileKey, playerVisibilityByTile);
      final isVisible = visibility != TileVisibility.unexplored;

      String char = ' ';
      if (!isVisible) {
        // Unexplored: show distinct character so visibility is clear
        // (e.g. New World at game start).
        buffer.write('?');
        continue;
      }

      final terrain = tileMap.terrainAt(x, y);
      switch (layer) {
        case MapGridLayer.terrain:
          char = terrainToChar(terrain);
          break;
        case MapGridLayer.political:
          final province = provincesById[fullProvinceId];
          final ownerId = province?.ownerId;
          final playerType = getPlayerType(ownerId, players);
          char = ownerToChar(ownerId, playerType);
          break;
        case MapGridLayer.resources:
          final resource = tileMap.resourceAt(x, y);
          char =
              resource != null ? resourceToChar(resource) : terrainToChar(terrain);
          break;
        case MapGridLayer.units:
          final unitChar = unitSymbolByTileKey?[fullTileKey];
          char = unitChar ?? terrainToChar(terrain);
          break;
      }
      buffer.write(char);
    }
    lines.add(buffer.toString());
  }
  return lines;
}

({int x, int y})? getProvinceTilePosition(
  TileMapResult tileMap,
  String provinceId,
) {
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      if (tileMap.cell(x, y) == provinceId) {
        return (x: x, y: y);
      }
    }
  }
  return null;
}

/// Builds a map of province IDs to Province objects from a region.
Map<String, Province> buildProvincesMap(List<Province> provinces) {
  return {for (final p in provinces) p.id: p};
}

/// Gets capital tile keys from game data.
Set<String> getCapitalTiles(Game game) {
  final tiles = <String>{};

  for (final player in game.players) {
    final capitalTile = player.capitalTile;
    if (capitalTile != null) {
      // CapitalTile has toTileKey() method
      tiles.add(capitalTile.toTileKey());
    }
  }

  return tiles;
}

/// Gets port tile keys from world state.
Set<String> getPortTiles(WorldState worldState) {
  final tiles = <String>{};

  final portsByProv = worldState.portsByProvinceSeaboard;
  // portsByProvinceSeaboard is Map<String, String> - provinceId -> tileKey
  for (final portTile in portsByProv.values) {
    if (portTile.isNotEmpty) {
      tiles.add(portTile);
    }
  }

  return tiles;
}

