/// Shared map formatting utilities for tile keys and game-derived view options.
/// Used by ctdev and other map frontends.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'tile_key_util.dart';

/// Short display form for a tile key (regionId|provinceId|x|y).
/// Returns "x,y" when the key has at least 4 pipe-separated parts; otherwise returns [tileKey] unchanged.
String formatTileKey(String tileKey) {
  final parsed = tryParseMapTileKey(tileKey);
  if (parsed != null) return '${parsed.x},${parsed.y}';
  return tileKey;
}

/// Converts [Game.greatPowerColorOverride] (list form) to tuple form for [buildInitGameMapViewData].
/// Use when building map view from a loaded game (Load Savegame flow).
Map<String, (int r, int g, int b)>? greatPowerColorOverrideFromGame(Game game) {
  final raw = game.greatPowerColorOverride;
  if (raw == null || raw.isEmpty) return null;
  return raw.map((k, v) => MapEntry(k, (v[0], v[1], v[2])));
}
