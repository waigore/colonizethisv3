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

/// Converts owner ID to its ASCII character representation for the political layer.
/// Great Powers use an uppercase first letter; all other owners (minors, tribes)
/// use a lowercase first letter. Unclaimed tiles use `·`.
String ownerToChar(String? ownerId, PlayerType? playerType) {
  if (ownerId == null) return '·'; // Unclaimed/wilderness

  final first = ownerId.substring(0, 1);

  if (playerType == PlayerType.greatPower) {
    return first.toUpperCase();
  }

  // For non-Great-Power owners (minor nations, tribes, or unknown type),
  // use a lowercase first letter so the political layer remains 1-char-per-tile.
  return first.toLowerCase();
}

