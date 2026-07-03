// Shared pure helpers for faction ownership collection and "Faction Setup"
// table rendering used by the init orchestrator and ownership assignment.
// SPEC/program/game-setup-pipeline.md (step 7 faction setup tables, ownership).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Province ids owned by [factionId] within [provinces], preserving the source
/// iteration order. When [sorted] (the default) the ids are returned in
/// ascending order, matching the setup-table and ownership collection contracts.
List<String> ownedProvinceIdsForFaction(
  Iterable<Province> provinces,
  String factionId, {
  bool sorted = true,
}) {
  final owned = <String>[
    for (final pr in provinces)
      if (pr.ownerId == factionId) pr.id,
  ];
  if (sorted) owned.sort();
  return owned;
}

/// Provinces owned by [factionId] within [provinces]. When [sorted] (the
/// default) the provinces are ordered by ascending id, matching the province
/// naming collection contract; pass `sorted: false` to preserve the source
/// iteration order (used by Great Power naming, which assigns names in the
/// order provinces appear in the region list).
List<Province> ownedProvincesForFaction(
  Iterable<Province> provinces,
  String factionId, {
  bool sorted = true,
}) {
  final owned = <Province>[
    for (final pr in provinces)
      if (pr.ownerId == factionId) pr,
  ];
  if (sorted) owned.sort((a, b) => a.id.compareTo(b.id));
  return owned;
}

/// One faction row for the "Faction Setup" markdown table. [capitalProvinceId]
/// renders as an em dash when null, and [ownedProvinceIds] are comma-joined.
String factionSetupTableRow({
  required String displayLabel,
  required String factionId,
  required String typeLabel,
  required String? capitalProvinceId,
  required List<String> ownedProvinceIds,
}) {
  final capital = capitalProvinceId ?? '—';
  return '| $displayLabel ($factionId) | $typeLabel | $capital '
      '| ${ownedProvinceIds.join(", ")} |';
}

/// Visits players, then minor nations, then tribes in slot order — the
/// canonical setup-faction iteration skeleton (Refs #3840).
void forEachSetupFaction(
  Game game, {
  required void Function(Player player) onPlayer,
  required void Function(MinorNation minorNation) onMinorNation,
  required void Function(Tribe tribe) onTribe,
}) {
  for (final player in game.players) {
    onPlayer(player);
  }
  for (final minor in game.minorNations) {
    onMinorNation(minor);
  }
  for (final tribe in game.tribes) {
    onTribe(tribe);
  }
}

/// Capital province and tile-key maps for factions that have both set.
/// Single source of truth for the triple-faction capital-collection loops
/// previously duplicated in town assignment (Refs #3840).
({
  Map<String, String> capitalProvinceIdByOwner,
  Map<String, String> capitalTileKeyByOwner,
})
collectCapitalMapsByOwner(Game game) {
  final capitalTileKeyByOwner = <String, String>{};
  final capitalProvinceIdByOwner = <String, String>{};

  void addCapital(String id, String? provinceId, CapitalTile? tile) {
    if (provinceId == null || tile == null) return;
    capitalProvinceIdByOwner[id] = provinceId;
    capitalTileKeyByOwner[id] = tile.toTileKey();
  }

  forEachSetupFaction(
    game,
    onPlayer: (p) => addCapital(p.id, p.capitalProvinceId, p.capitalTile),
    onMinorNation: (m) => addCapital(m.id, m.capitalProvinceId, m.capitalTile),
    onTribe: (t) => addCapital(t.id, t.capitalProvinceId, t.capitalTile),
  );

  return (
    capitalProvinceIdByOwner: capitalProvinceIdByOwner,
    capitalTileKeyByOwner: capitalTileKeyByOwner,
  );
}

/// Civilian-owning factions for starting-unit spawn. Great Powers require a
/// capital tile; minors and tribes may omit one.
Iterable<
  ({
    String id,
    String? capitalProvinceId,
    CapitalTile? capitalTile,
    bool requireCapitalTile,
  })
>
setupCivilianOwnerRecords(Game game) sync* {
  for (final player in game.players) {
    yield (
      id: player.id,
      capitalProvinceId: player.capitalProvinceId,
      capitalTile: player.capitalTile,
      requireCapitalTile: true,
    );
  }
  for (final minor in game.minorNations) {
    yield (
      id: minor.id,
      capitalProvinceId: minor.capitalProvinceId,
      capitalTile: minor.capitalTile,
      requireCapitalTile: false,
    );
  }
  for (final tribe in game.tribes) {
    yield (
      id: tribe.id,
      capitalProvinceId: tribe.capitalProvinceId,
      capitalTile: tribe.capitalTile,
      requireCapitalTile: false,
    );
  }
}
