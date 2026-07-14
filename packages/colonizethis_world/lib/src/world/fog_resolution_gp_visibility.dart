import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_traversal.dart';
import 'topology_helpers.dart';
import 'visibility_map_helpers.dart' show mutableVisibilityByPlayerCopy;

/// Shared Great-Power visibility iteration helpers for coastal/distant fog
/// passes (Refs #3968). Extracted from the former `fog_resolution.dart` part
/// library so standalone fog modules can import them explicitly.

/// Returns a deep mutable copy of [visibility] (per-player tile visibility maps)
/// so each Great-Power pass can mutate its own player's map in place without
/// aliasing the caller's input.
///
/// Delegates to [mutableVisibilityByPlayerCopy] so ownership/spy/coastal paths
/// share one copy idiom (Refs #3968).
Map<String, Map<String, String>> mutableGpVisibilityCopy(
  Map<String, Map<String, String>> visibility,
) => mutableVisibilityByPlayerCopy(visibility);

/// Invokes [action] with each Great-Power player's mutable visibility map from
/// [result], skipping non-GP players and players without a visibility entry.
void forEachGpPlayerVisibility({
  required Game game,
  required Set<String> gpIds,
  required Map<String, Map<String, String>> result,
  required void Function(String playerId, Map<String, String> vis) action,
}) {
  for (final player in game.players) {
    if (!gpIds.contains(player.id)) continue;
    final vis = result[player.id];
    if (vis == null) continue;
    action(player.id, vis);
  }
}

/// Shared per-region Great-Power visibility iteration for the coastal/distant
/// sea-zone fog passes. Returns a fresh deep-mutable copy of [visibility]; for
/// every world region that has tile-key buckets it resolves the region topology
/// and invokes [perRegion] with the region id, its topology, its tile-key
/// buckets, and a `forEachGpPlayer` callback the caller drives once any
/// per-region precomputation is ready. `forEachGpPlayer` walks each GP player's
/// mutable visibility map (from the returned copy) so callers mutate in place.
Map<String, Map<String, String>> forEachWorldRegionGpVisibility({
  required Game game,
  required Map<String, Map<String, String>> visibility,
  required MapTopology topology,
  Map<String, MapTopology>? topologyByRegion,
  required void Function(
    String regionId,
    MapTopology regionTopology,
    Map<String, List<String>> regionTileKeys,
    void Function(void Function(String playerId, Map<String, String> vis))
    forEachGpPlayer,
  )
  perRegion,
}) {
  final gpIds = game.players.map((p) => p.id).toSet();
  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final result = mutableGpVisibilityCopy(visibility);

  forEachWorldRegion(game.worldState, (regionId, _) {
    final regionTileKeys = tileKeysByRegion[regionId];
    if (regionTileKeys == null) return;
    final regionTopology = topologyForRegion(
      topology,
      regionId,
      topologyByRegion: topologyByRegion,
    );
    perRegion(regionId, regionTopology, regionTileKeys, (action) {
      forEachGpPlayerVisibility(
        game: game,
        gpIds: gpIds,
        result: result,
        action: action,
      );
    });
  });

  return result;
}
