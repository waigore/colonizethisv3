import '../world/player_view.dart';

/// True when [landTileKeysInProvince] for this player has at least one tile at
/// [VisibilityLevel.unknown] and at least one at fogged or fully visible.
///
/// SPEC: `SPEC/game/fog-and-exploration.md` (partially revealed province).
bool isPartiallyRevealedProvinceLandTilesForPlayer(
  PlayerView view,
  Iterable<String> landTileKeysInProvince,
) {
  var hasKnown = false;
  var hasUnknown = false;
  for (final tileKey in landTileKeysInProvince) {
    final level = view.visibilityForTile(tileKey);
    if (level == VisibilityLevel.unknown) {
      hasUnknown = true;
    } else {
      hasKnown = true;
    }
    if (hasKnown && hasUnknown) {
      return true;
    }
  }
  return false;
}
