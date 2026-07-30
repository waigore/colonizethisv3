/// Visibility helpers for Development panel improvable tile filtering. Refs #4175.
library;

import 'package:colonizethis_world/colonizethis_world.dart';

/// True when [tileKey] is known to the player (visible or fogged).
bool developmentTileVisibilityKnown(PlayerView playerView, String tileKey) {
  final visibility = playerView.visibilityForTile(tileKey);
  return visibility == VisibilityLevel.fullyVisible ||
      visibility == VisibilityLevel.fogged;
}

List<String> developmentFilterVisibilityKnownTileKeys(
  PlayerView playerView,
  Iterable<String> tileKeys,
) {
  return [
    for (final tileKey in tileKeys)
      if (developmentTileVisibilityKnown(playerView, tileKey)) tileKey,
  ];
}
