/// Province name label plate tint (Great Power colour vs neutral).
/// SPEC/ui/map-widget.md § Layer model (province names).
library;

import 'view/init_game_map_view_data.dart';

/// Alpha for GP-tinted label plate (semi-transparent; matches legacy neutral plate strength).
const double kProvinceLabelPlateTintAlpha = 0.55;

/// Returns RGB for a GP-tinted name plate, or `null` to use the neutral (e.g. dark) plate.
///
/// When [region.provincePoliticalOwnerByPrefixedProvinceId] contains [prefixedProvinceId],
/// the **province-level** owner from world state drives eligibility: tinted only if that
/// owner is a Great Power, every [qualifyingLandCells] entry matches that owner on
/// [CellViewData.ownerFactionId], and [factionColors] has an entry. Minor/Tribe
/// provinces (including with GP-purchased tiles once per-tile owners diverge) therefore
/// yield `null`.
///
/// When the political map has no entry for [prefixedProvinceId] (e.g. hand-built test
/// data), falls back to “all qualifying cells share one GP owner” for backward
/// compatibility.
Rgb? resolveProvinceLabelPlateTintRgb({
  required String prefixedProvinceId,
  required List<CellViewData> qualifyingLandCells,
  required RegionMapViewData region,
  required bool honorUnrevealedTiles,
}) {
  final cells = <CellViewData>[];
  for (final c in qualifyingLandCells) {
    if (c.isSea) {
      continue;
    }
    if (honorUnrevealedTiles && c.visibility == TileVisibility.unrevealed) {
      continue;
    }
    cells.add(c);
  }
  if (cells.isEmpty) {
    return null;
  }

  final politicalMap = region.provincePoliticalOwnerByPrefixedProvinceId;
  if (politicalMap.containsKey(prefixedProvinceId)) {
    final politicalOwner = politicalMap[prefixedProvinceId];
    if (politicalOwner == null || politicalOwner.isEmpty) {
      return null;
    }
    if (!region.greatPowerFactionIds.contains(politicalOwner)) {
      return null;
    }
    for (final c in cells) {
      if (c.ownerFactionId != politicalOwner) {
        return null;
      }
    }
    return region.factionColors[politicalOwner];
  }

  final firstOwner = cells.first.ownerFactionId;
  if (firstOwner == null || firstOwner.isEmpty) {
    return null;
  }
  if (!region.greatPowerFactionIds.contains(firstOwner)) {
    return null;
  }
  for (final c in cells) {
    if (c.ownerFactionId != firstOwner) {
      return null;
    }
  }
  return region.factionColors[firstOwner];
}
