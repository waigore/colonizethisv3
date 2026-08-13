import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_choice.dart';
import 'faction_setup_helpers.dart';
import 'game_setup_ownership_remainder_factions.dart';
import 'game_setup_plains_conversion.dart';
import 'game_setup_topology.dart';
import 'locked_province_assigner_types.dart';

export 'game_setup_ownership_comparators.dart';
export 'game_setup_ownership_old_world.dart';
export 'game_setup_ownership_old_world_contiguous.dart';
export 'game_setup_ownership_old_world_seeds.dart';

Game assignCapitalsForFactions({
  required Game game,
  required List<String> factionIds,
  required List<Province> provinces,
  required String regionId,
  required MapTopology topology,
  required TileMapResult tileMap,
  required Map<String, TileMapResult> tileMapByRegion,
  required bool requireSeaBound,
  required Game Function(
    Game,
    String,
    String,
    CapitalTile,
    MapTopology,
    Map<String, TileMapResult>,
  )
  setCapitalFn,
}) {
  for (final factionId in factionIds) {
    final owned = ownedProvinceIdsForFaction(
      provinces,
      factionId,
      sorted: false,
    );
    if (owned.isEmpty) continue;
    final mapForPick = tileMapByRegion[regionId] ?? tileMap;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      regionId,
      topology,
      mapForPick,
      requireSeaBound: requireSeaBound,
    );
    final ensured = ensureTileIsPlains(
      game: game,
      tileMapByRegion: tileMapByRegion,
      tileKey: tile.toTileKey(),
    );
    game = ensured.game;
    game = setCapitalFn(
      game,
      factionId,
      provinceId,
      tile,
      topology,
      tileMapByRegion,
    );
  }
  return game;
}

Map<String, String> assignNewWorldOwnershipContiguous({
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  if (tribeIds.isEmpty) {
    return {for (final p in provinceIds) p: ''};
  }

  final neighbours = provinceNeighboursFromTopology(topologyNewWorld);
  final universe = provinceIds.toSet();
  return assignFactionsOnRemainderAuto(
    factionIds: tribeIds,
    universe: Set<String>.from(universe),
    neighbours: neighbours,
    assignmentRandom: null,
    backtrackLimitPerFaction: kDefaultBacktrackLimitPerFaction,
  );
}
