import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';

/// Prefixed province ids whose land tile keys show mixed unknown vs known
/// visibility for [view] (see [isPartiallyRevealedProvinceLandTilesForPlayer]).
///
/// Used by explore work suggestions and valid-tile enumeration (Refs #2394).
Set<String> partiallyRevealedPrefixedProvinceIdsForPlayer({
  required Game game,
  required PlayerView view,
}) {
  final cached = <String>{};
  for (final regionEntry
      in game.worldState.tileKeysByRegionAndProvince.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (isPartiallyRevealedProvinceLandTilesForPlayer(
        view,
        provinceEntry.value,
      )) {
        cached.add(provinceId);
      }
    }
  }
  return cached;
}

/// Province rows for [partiallyRevealedPrefixedProvinceIds], sorted by full
/// province id. Built once per work-suggestion pass and shared across explorer
/// units via O(1) [PlayerView.provincesById] lookups instead of
/// [allProvinces] (Refs #2394).
///
/// When the id set is empty, returns a constant empty list without scanning.
List<Province> sortedProvincesForPartialRevealPrefixedIds({
  required PlayerView view,
  required Set<String> partiallyRevealedPrefixedProvinceIds,
}) {
  if (partiallyRevealedPrefixedProvinceIds.isEmpty) {
    return const [];
  }
  final out = <Province>[
    for (final id in partiallyRevealedPrefixedProvinceIds)
      if (view.provincesById[id] != null) view.provincesById[id]!,
  ];
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}

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
