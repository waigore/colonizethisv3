// Advanced-start NW colonization (step 10). SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_bootstrap_roads.dart';
import 'advanced_start_nw_topology.dart';
import 'game_setup_helpers_towns.dart';
import 'game_setup_topology.dart';
import 'setup_logging.dart';

String _fullNwProvinceId(String localId) =>
    ProvinceId.full(kRegionNewWorld, localId);

String? _tribeOwnerForLocalProvince(Game game, String localProvinceId) {
  final fullId = _fullNwProvinceId(localProvinceId);
  for (final province in game.worldState.newWorld.provinces) {
    final id = ProvinceId.isPrefixed(province.id)
        ? province.id
        : ProvinceId.full(province.regionId, province.id);
    if (id != fullId) continue;
    final ownerId = province.ownerId;
    if (ownerId != null && game.tribes.any((t) => t.id == ownerId)) {
      return ownerId;
    }
  }
  return null;
}

Map<String, int> _tribeProvinceCounts(Game game) {
  final counts = <String, int>{for (final t in game.tribes) t.id: 0};
  for (final province in game.worldState.newWorld.provinces) {
    final ownerId = province.ownerId;
    if (ownerId != null && counts.containsKey(ownerId)) {
      counts[ownerId] = counts[ownerId]! + 1;
    }
  }
  return counts;
}

/// Attempts to assign [current] to [playerId]. Returns true only when the
/// province is tribe-owned, not yet assigned to a GP, and the owning tribe
/// would retain at least one province afterward (expand-on-accept contract
/// consumed by [advancedStartFloodFillProvinces]).
bool _tryAssignNwProvince({
  required String current,
  required String playerId,
  required Game game,
  required Map<String, String> assignedToGp,
  required Map<String, int> tribeCounts,
}) {
  if (assignedToGp.containsKey(current)) return false;

  final tribeOwner = _tribeOwnerForLocalProvince(game, current);
  if (tribeOwner == null) return false;
  if ((tribeCounts[tribeOwner] ?? 0) <= 1) return false;

  assignedToGp[current] = playerId;
  tribeCounts[tribeOwner] = tribeCounts[tribeOwner]! - 1;
  return true;
}

Game applyAdvancedStartNwColonization({
  required Game game,
  required AdvancedStartType startType,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required List<WarpLink> warpLinks,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  final targetCount = advancedStartNwColonizationCount(startType);
  if (targetCount <= 0) return game;

  final nwMap = tileMapByRegion[kRegionNewWorld];
  final nwTopology = topologyByRegion[kRegionNewWorld] ?? topologyNewWorld;
  if (nwMap == null) {
    setupLog.w('logic: advanced start NW colonization skipped — no NW tile map');
    return game;
  }

  final provinceNeighbours = provinceNeighboursFromTopology(nwTopology);
  final assignedToGp = <String, String>{};
  var tribeCounts = _tribeProvinceCounts(game);

  for (final player in game.players) {
    final capitalProvinceId = player.capitalProvinceId;
    if (capitalProvinceId == null) continue;
    final capitalLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    final seeds = advancedStartNwEntryProvinceLocalIds(
      capitalLocalProvinceId: capitalLocalId,
      topologyOldWorld: topologyOldWorld,
      warpLinks: warpLinks,
      topologyNewWorld: nwTopology,
    );
    if (seeds.isEmpty) {
      setupLog.w(
        'logic: advanced start NW colonization skipped for ${player.id} — '
        'no warp entry',
      );
      continue;
    }

    final collected = advancedStartFloodFillProvinces(
      provinceNeighbours: provinceNeighbours,
      seedLocalIds: seeds,
      targetCount: targetCount,
      accept: (current) => _tryAssignNwProvince(
        current: current,
        playerId: player.id,
        game: game,
        assignedToGp: assignedToGp,
        tribeCounts: tribeCounts,
      ),
    );

    if (collected.length < targetCount) {
      setupLog.w(
        'logic: advanced start NW colonization for ${player.id} assigned '
        '${collected.length}/$targetCount provinces',
      );
    }
  }

  if (assignedToGp.isEmpty) return game;

  final updatedProvinces = game.worldState.newWorld.provinces.map((province) {
    final localId = ProvinceId.isPrefixed(province.id)
        ? ProvinceId.localIdFrom(province.id)
        : province.id;
    final gpId = assignedToGp[localId];
    if (gpId == null) return province;
    return province.copyWith(ownerId: gpId);
  }).toList();

  var updated = game.copyWith(
    worldState: game.worldState.copyWith(
      newWorld: RegionData(
        provinces: updatedProvinces,
        units: game.worldState.newWorld.units,
      ),
    ),
  );

  updated = assignProvinceTowns(
    game: updated,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );

  var ws = updated.worldState;
  for (final entry in assignedToGp.entries) {
    final provinceId = _fullNwProvinceId(entry.key);
    final province = ws.newWorld.provinces
        .where((p) {
          final id = ProvinceId.isPrefixed(p.id)
              ? p.id
              : ProvinceId.full(p.regionId, p.id);
          return id == provinceId;
        })
        .singleOrNull;
    final townKey = province?.townTileKey;
    if (townKey == null) continue;
    ws = applySeaboardPortAndRoadToTile(
      worldState: ws,
      provinceId: provinceId,
      inlandTileKey: townKey,
      topology: nwTopology,
      map: nwMap,
    );
  }

  setupLog.i(
    'logic: advanced start NW colonization assigned ${assignedToGp.length} '
    'provinces across ${game.players.length} GPs',
  );

  return updated.copyWith(worldState: ws);
}
