/// Rules for Great Power land ownership tint on the app map.
/// SPEC/ui/map-widget.md § Province overlay.
library;

import 'view/init_game_map_view_data.dart';

/// Returns true when the map should draw the semi-transparent GP tint on [cell].
///
/// [honorUnrevealedTiles]: when true (player-constrained visibility), tiles with
/// [TileVisibility.unrevealed] are excluded; [visible] and [fogged] use the same rules.
bool shouldApplyGreatPowerOwnershipTint({
  required CellViewData cell,
  required Set<String> greatPowerFactionIds,
  required bool honorUnrevealedTiles,
}) {
  if (cell.isSea) return false;
  if (honorUnrevealedTiles && cell.visibility == TileVisibility.unrevealed) {
    return false;
  }
  final owner = cell.ownerFactionId;
  if (owner == null || owner.isEmpty) return false;
  return greatPowerFactionIds.contains(owner);
}
