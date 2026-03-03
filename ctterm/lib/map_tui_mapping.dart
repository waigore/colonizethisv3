// Map TUI mapping: converts game map data to ASCII/Unicode terminal display.
// SPEC/tui/map-tui-mapping.md

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Converts a terrain type to its ASCII character representation.
String terrainToChar(TerrainType? terrain) {
  switch (terrain) {
    case TerrainType.plains:
      return '.';
    case TerrainType.forest:
      return '♣';
    case TerrainType.hills:
      return '^';
    case TerrainType.mountain:
      return '▲';
    case TerrainType.swamp:
      return '≈';
    case TerrainType.desert:
      return '▒';
    case null:
      // null terrain means water/sea
      return '~';
  }
}

/// Gets the character representation for a resource.
String resourceToChar(Resource? resource) {
  if (resource == null) return '';
  
  // Single-letter codes for common resources
  switch (resource) {
    case Resource.grain:
      return 'g';
    case Resource.meat:
      return 'm';
    case Resource.wool:
      return 'w';
    case Resource.horses:
      return 'h';
    case Resource.timber:
      return 't';
    case Resource.iron:
      return 'i';
    case Resource.copper:
      return 'c';
    case Resource.tin:
      return 'n';
    case Resource.coal:
      return 'k';
    case Resource.sugarCane:
      return 's';
    case Resource.tobacco:
      return 'b';
    case Resource.cotton:
      return 'u';
    case Resource.furs:
      return 'f';
    case Resource.spices:
      return 'p';
    case Resource.silver:
      return 'v';
    case Resource.gold:
      return 'G';
    case Resource.gems:
      return 'e';
    case Resource.diamonds:
      return 'd';
  }
}

/// Determines owner type from player data.
enum PlayerType { greatPower, minorNation, tribe }

/// Gets the owner type for a player ID.
/// Players with isHuman=true are Great Powers (at game start).
/// Tribes are AI-controlled but have territory in New World.
PlayerType? getPlayerType(String? ownerId, List<Player> players) {
  if (ownerId == null) return null;
  
  final player = players.where((p) => p.id == ownerId).firstOrNull;
  if (player == null) return null;
  
  // Human players are Great Powers
  if (player.isHuman) return PlayerType.greatPower;
  
  // For AI players, we need game context to determine if they're a tribe
  // For now, treat all AI non-humans as minor nations (could be tribes in NW)
  return PlayerType.minorNation;
}

/// Converts owner ID to its ASCII character prefix.
String ownerToChar(String? ownerId, PlayerType? playerType) {
  if (ownerId == null) return '·'; // Unclaimed/wilderness
  
  switch (playerType) {
    case PlayerType.greatPower:
      // First letter of GP ID, uppercase
      return ownerId.substring(0, 1).toUpperCase();
    case PlayerType.minorNation:
      // 'm' prefix + first letter
      return 'm${ownerId.substring(0, 1).toLowerCase()}';
    case PlayerType.tribe:
      // 't' prefix + first letter
      return 't${ownerId.substring(0, 1).toLowerCase()}';
    case null:
      return '·';
  }
}

/// Visibility level for a tile.
enum TileVisibility { unexplored, fogged, revealed, fullyVisible }

/// Gets visibility level from player visibility map.
TileVisibility getTileVisibility(
  String tileKey,
  Map<String, String>? playerVisibilityByTile,
) {
  if (playerVisibilityByTile == null) return TileVisibility.unexplored;
  
  final level = playerVisibilityByTile[tileKey];
  switch (level) {
    case 'fullyVisible':
      return TileVisibility.fullyVisible;
    case 'fogged':
      return TileVisibility.fogged;
    case 'revealed':
      return TileVisibility.revealed;
    case null:
    default:
      return TileVisibility.unexplored;
  }
}

/// Checks if a tile is at least revealed (visible info shown).
bool isTileVisible(
  String tileKey,
  Map<String, String>? playerVisibilityByTile,
) {
  final visibility = getTileVisibility(tileKey, playerVisibilityByTile);
  return visibility == TileVisibility.fullyVisible ||
         visibility == TileVisibility.revealed ||
         visibility == TileVisibility.fogged;
}

/// Checks if a tile is fully visible (no fog).
bool isTileFullyVisible(
  String tileKey,
  Map<String, String>? playerVisibilityByTile,
) {
  return getTileVisibility(tileKey, playerVisibilityByTile) == TileVisibility.fullyVisible;
}

/// Gets a tile's region ID from the grid.
String? getTileRegionId(TileMapResult tileMap, int x, int y) {
  if (x < 0 || x >= tileMap.width || y < 0 || y >= tileMap.height) {
    return null;
  }
  return tileMap.cell(x, y);
}

/// Generates a tile key in format "regionId|x|y".
String makeTileKey(String regionId, int x, int y) {
  return '$regionId|$x|$y';
}

/// Full tile key per SPEC/game/world-model-identity.md: regionId|localId|x|y.
String makeFullTileKey(String regionId, String localId, int x, int y) {
  return '$regionId|$localId|$x|$y';
}

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
  final width = maxWidth != null && maxWidth < tileMap.width ? maxWidth : tileMap.width;
  final height = maxHeight != null && maxHeight < tileMap.height ? maxHeight : tileMap.height;
  
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
/// [offsetX], [offsetY] are the top-left cell of the viewport; [viewportWidth] and [viewportHeight] are the visible size.
/// [layer] selects which layer to display (terrain, political, resources, units).
/// [unitSymbolByTileKey] maps full tile key (regionId|localId|x|y) to a character for the units layer; only used when [layer] is [MapGridLayer.units].
/// Visibility is from [playerVisibilityByTile] (game setup gives the human player visibility of their own provinces).
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
        // Unexplored: show distinct character so visibility is clear (e.g. New World at game start).
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
          char = resource != null ? resourceToChar(resource) : terrainToChar(terrain);
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
({int x, int y })? getProvinceTilePosition(
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
