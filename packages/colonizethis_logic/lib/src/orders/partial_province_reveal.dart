import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';
import '../world/province_lookup.dart';

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
/// units instead of rescanning [allProvinces] per unit (Refs #2394).
///
/// When the id set is empty, returns a constant empty list without scanning.
List<Province> sortedProvincesForPartialRevealPrefixedIds({
  required WorldState world,
  required Set<String> partiallyRevealedPrefixedProvinceIds,
}) {
  if (partiallyRevealedPrefixedProvinceIds.isEmpty) {
    return const [];
  }
  final out = <Province>[
    for (final p in allProvinces(world))
      if (partiallyRevealedPrefixedProvinceIds.contains(p.id)) p,
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
