import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_blockade_target.dart';
import 'connectivity_faction_input.dart';
import 'connectivity_metrics.dart';
import 'connectivity_result.dart';
import 'diplomatic_relation_lookup.dart';

// Re-export so deep importers of `connectivity_resolver.dart` (e.g. economy
// tests) keep seeing `ConnectivityResult` after its extraction to its own
// library (Refs #3544 Step 3). The package barrel exports the class via this
// re-export, preserving the public surface.
export 'connectivity_result.dart';

/// Resolves which tiles are connected to each player's capital. SPEC/game/capital-and-connectivity.
///
/// Connectivity: from capital, BFS over land; edges are same-province adjacency;
/// we expand only from capital or tiles with road/port. Overseas: ports connected
/// by shared sea zone; from those ports, BFS within province by road/adjacency.
/// Also computes [ConnectivityResult.pathTransportCap]: for each connected tile,
/// the maximum over paths from capital of (min road/port level on that path).

/// Blockade state: per player, the set of port province ids (full prefixed) that are blockaded.
///
/// A province is blockaded for its owner when an **enemy fleet at sea** (at war) is on Blockade
/// mission targeting it and the fleet's sea zone is **adjacent to that province's port**.
/// SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, Set<String>> computeBlockadedPortProvincesByPlayer(
  Game game,
  MapTopology topology,
) {
  final result = <String, Set<String>>{};
  for (final player in game.players) {
    result[player.id] = {};
  }
  final fleets = game.worldState.fleets;
  for (final fleet in fleets) {
    final ownerId = blockadedProvinceOwnerIdForFleet(
      fleet: fleet,
      worldState: game.worldState,
      topology: topology,
      areFactionsAtWar: (attackerFactionId, defenderFactionId) =>
          factionsAtWar(game, attackerFactionId, defenderFactionId),
    );
    if (ownerId == null) continue;
    final targetProvinceId = fleet.targetProvinceId!;
    result[ownerId] ??= {};
    result[ownerId]!.add(targetProvinceId);
  }
  return result;
}

/// Returns per player id [ConnectivityResult] (connected set + path transport cap).
/// Players without capital or with no tile map get an empty result.
/// When [blockadedPortProvincesByPlayerId] is null, it is computed from [game] (fleets on Blockade mission, at war). SPEC/game/capital-and-connectivity.md § Blockade.
Map<String, ConnectivityResult> resolveConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  Map<String, Set<String>>? blockadedPortProvincesByPlayerId,
  ConnectivityHotPathMetrics? metrics,
  Set<String>? onlyPlayerIds,
}) {
  worldLog.d(
    'connectivity resolve start players=${game.players.length} regions=${tileMapByRegion.keys.join(",")}',
  );
  final blockadedByPlayer =
      blockadedPortProvincesByPlayerId ??
      computeBlockadedPortProvincesByPlayer(game, topology);
  final input = ConnectivityFactionInput.fromGame(
    game: game,
    topology: topology,
  );
  final result = <String, ConnectivityResult>{};

  for (final player in game.players) {
    if (onlyPlayerIds != null && !onlyPlayerIds.contains(player.id)) {
      continue;
    }
    _putFactionConnectivityResult(
      result: result,
      input: input,
      game: game,
      factionId: player.id,
      capitalTile: player.capitalTile,
      capitalProvinceId: player.capitalProvinceId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      blockadedPortProvinces: blockadedByPlayer[player.id] ?? const {},
      metrics: metrics,
      skipLogMessage:
          'connectivity resolve player=${player.id} skipped (no capital)',
    );
  }

  final summary = result.entries
      .map((e) => '${e.key}:${e.value.connected.length}')
      .join(' ');
  worldLog.d('connectivity resolve end $summary');
  return result;
}

/// Returns per-faction [ConnectivityResult] for **non-Great-Power factions**
/// (Minor Nations and Tribes). Keys are `MinorNation.id` and `Tribe.id`; there
/// is no overlap with Great Power player ids returned by [resolveConnectivity].
///
/// Iterates `Game.minorNations` and `Game.tribes` instead of `Game.players` and
/// shares the same Road and Town rules as Great Power connectivity per
/// [SPEC/game/capital-and-connectivity.md] § Connectivity (Game Rule). Three
/// non-Great-Power-specific differences are normative in
/// [SPEC/game/capital-and-connectivity.md] § Non-Great-Power capital connectivity
/// and [SPEC/game/factions.md] § Minor and Tribe capital connectivity:
///
///   1. **Land-only output.** Minors and Tribes do not own provinces in the
///      other region; the overseas branch in § Connectivity (Game Rule) cannot
///      match because of the per-faction ownership filter.
///   2. **No blockade interaction.** The resolver passes an **empty** blockade
///      set so World-Market participation is independent of fleets on Blockade
///      missions, per [SPEC/game/world-market.md] § Minor and tribe auto-sell.
///   3. **No GP-only town-development bump.** Capital-province
///      `townDevelopmentLevel = 4` is set for Great Powers only.
///
/// Factions with `capitalTile == null` or `capitalProvinceId == null` (e.g.
/// before [SPEC/game/capital-and-connectivity.md] § Minor Nation and Tribe
/// terminal fall removes the entry) are emitted with an empty
/// [ConnectivityResult]. Empty `Game.minorNations` and `Game.tribes` returns
/// an empty map without iterating Great Power state.
///
/// Output is consumed by `computeNonGreatPowerExtraction` (issue #2991 C2 in
/// `economy/non_gp_extraction.dart`) which treats the result as the per-faction
/// connectivity input it does not compute itself.
Map<String, ConnectivityResult> resolveNonGreatPowerConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  ConnectivityHotPathMetrics? metrics,
}) {
  if (game.minorNations.isEmpty && game.tribes.isEmpty) {
    return const <String, ConnectivityResult>{};
  }
  worldLog.d(
    'non_gp connectivity resolve start minors=${game.minorNations.length} '
    'tribes=${game.tribes.length} '
    'regions=${tileMapByRegion.keys.join(",")}',
  );
  final input = ConnectivityFactionInput.fromGame(
    game: game,
    topology: topology,
  );
  final result = <String, ConnectivityResult>{};

  for (final minor in game.minorNations) {
    _putFactionConnectivityResult(
      result: result,
      input: input,
      game: game,
      factionId: minor.id,
      capitalTile: minor.capitalTile,
      capitalProvinceId: minor.capitalProvinceId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      blockadedPortProvinces: const <String>{},
      metrics: metrics,
      skipLogMessage:
          'non_gp connectivity resolve faction=${minor.id} skipped (no capital)',
    );
  }
  for (final tribe in game.tribes) {
    _putFactionConnectivityResult(
      result: result,
      input: input,
      game: game,
      factionId: tribe.id,
      capitalTile: tribe.capitalTile,
      capitalProvinceId: tribe.capitalProvinceId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      blockadedPortProvinces: const <String>{},
      metrics: metrics,
      skipLogMessage:
          'non_gp connectivity resolve faction=${tribe.id} skipped (no capital)',
    );
  }

  final summary = result.entries
      .map((e) => '${e.key}:${e.value.connected.length}')
      .join(' ');
  worldLog.d('non_gp connectivity resolve end $summary');
  return result;
}

/// Shared per-faction resolve shell for GP and non-GP entrypoints (Refs #3978).
///
/// Policy (blockade set, faction source, log prefix) stays on the public
/// callers — this helper only centralizes missing-capital → empty result and
/// the [ConnectivityFactionInput.resolveFaction] call.
void _putFactionConnectivityResult({
  required Map<String, ConnectivityResult> result,
  required ConnectivityFactionInput input,
  required Game game,
  required String factionId,
  required CapitalTile? capitalTile,
  required String? capitalProvinceId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Set<String> blockadedPortProvinces,
  required String skipLogMessage,
  ConnectivityHotPathMetrics? metrics,
}) {
  if (capitalTile == null || capitalProvinceId == null) {
    worldLog.d(skipLogMessage);
    result[factionId] = const ConnectivityResult(connected: {});
    return;
  }
  result[factionId] = input.resolveFaction(
    game: game,
    factionId: factionId,
    capital: capitalTile,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
    blockadedPortProvinces: blockadedPortProvinces,
    metrics: metrics,
  );
}
