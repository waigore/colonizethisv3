import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_world_mutations.dart';
import 'naval.dart';
import 'naval_coastal_visibility.dart'
    show
        canonicalSeaZoneTileBucketKey,
        coastalLandTileKeysFromNavalPresenceAtSea;
import 'fog_spy_reveal_decay.dart';
import 'player_view.dart';
import 'province_lookup.dart';
import 'province_traversal.dart';
import 'tile_key_coordinates.dart';
import 'topology_helpers.dart';
import 'unit_lookup.dart';

part 'fog_resolution_explorer_spy_decay.dart';
part 'fog_resolution_province_ownership.dart';
part 'fog_resolution_coastal_sea_zone.dart';
part 'fog_resolution_distant_sea_zone.dart';

/// End-of-turn fog-of-war resolution for player visibility.
///
/// Behaviour is split by concern across part files of this library; all
/// top-level entry points remain importable from `fog_resolution.dart`:
///
/// - `fog_resolution_explorer_spy_decay.dart` — Explorer/Spy land fog decay and
///   Spy reveal-timer maintenance ([applySpyRevealTimerDecay], [applyFogDecay],
///   [clearSpyRevealTimersForProvince],
///   [clearSpyRevealTimersForProvinceOwnershipTransfer]).
/// - `fog_resolution_province_ownership.dart` — immediate visibility on province
///   ownership transfer ([applyProvinceOwnershipChangeVisibility]).
/// - `fog_resolution_coastal_sea_zone.dart` — coastal sea-zone full visibility
///   ([applyCoastalSeaZoneFullVisibility],
///   [applyCoastalSeaZoneFullVisibilityForProvinceTargets]).
/// - `fog_resolution_distant_sea_zone.dart` — distant sea-zone fog revert
///   ([applyDistantSeaZoneFogRevert]).
///
/// SPEC source of truth: SPEC/program/fog-and-exploration-resolution.md.

/// Returns a deep mutable copy of [visibility] (per-player tile visibility maps)
/// so each Great-Power pass can mutate its own player's map in place without
/// aliasing the caller's input.
Map<String, Map<String, String>> _mutableGpVisibilityCopy(
  Map<String, Map<String, String>> visibility,
) => {
  for (final entry in visibility.entries)
    entry.key: Map<String, String>.from(entry.value),
};

/// Invokes [action] with each Great-Power player's mutable visibility map from
/// [result], skipping non-GP players and players without a visibility entry.
void _forEachGpPlayerVisibility({
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
