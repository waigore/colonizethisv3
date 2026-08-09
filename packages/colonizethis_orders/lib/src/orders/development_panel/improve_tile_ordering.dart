/// Shared `build_improvement` tile ordering for Development assign and suggestions.
///
/// SPEC: SPEC/program/development-panel-read-model.md § Assign selection (Slice B)
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../connectivity_dev_snapshot.dart';
import '../connectivity_dev_targets.dart';
import '../feedstock_extraction_targets.dart'
    show feedstockExtractionResourceIdsForPlayer;

/// Compares improvable tiles for Development panel assign priority.
///
/// Connected tiles first, then lower improvement level, then stable tile key.
int compareDevelopmentImproveTilePriority({
  required String a,
  required String b,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
}) {
  final aConnected = connectedTileKeys.contains(a);
  final bConnected = connectedTileKeys.contains(b);
  if (aConnected != bConnected) {
    return aConnected ? -1 : 1;
  }
  final aLevel = tileState.improvementLevel(a);
  final bLevel = tileState.improvementLevel(b);
  if (aLevel != bLevel) {
    return aLevel.compareTo(bLevel);
  }
  return a.compareTo(b);
}

List<String> sortedDevelopmentImproveTileCandidates({
  required Iterable<String> tileKeys,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
}) {
  final sorted = tileKeys.toList()
    ..sort(
      (a, b) => compareDevelopmentImproveTilePriority(
        a: a,
        b: b,
        connectedTileKeys: connectedTileKeys,
        tileState: tileState,
      ),
    );
  return sorted;
}

/// Feedstock front/back partition with co-availability ordering in the front
/// partition. Matches the worker suggestion pre-connectivity step (Refs #2847).
List<String> prioritizeFeedstockBuildImprovementCandidates({
  required Game game,
  required String playerId,
  required List<String> sortedVisible,
}) {
  final feedstockIds = feedstockExtractionResourceIdsForPlayer(game, playerId);
  if (feedstockIds.isEmpty) return sortedVisible;
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final front = <String>[];
  final back = <String>[];
  for (final tileKey in sortedVisible) {
    final resourceId = resourceByTile[tileKey];
    if (resourceId != null &&
        feedstockIds.contains(resourceId) &&
        tileState.improvementLevel(tileKey) < 1) {
      front.add(tileKey);
    } else {
      back.add(tileKey);
    }
  }
  if (front.isEmpty) return sortedVisible;
  _orderFeedstockFrontByCoAvailability(
    game: game,
    playerId: playerId,
    resourceByTile: resourceByTile,
    front: front,
  );
  return <String>[...front, ...back];
}

void _orderFeedstockFrontByCoAvailability({
  required Game game,
  required String playerId,
  required Map<String, String> resourceByTile,
  required List<String> front,
}) {
  if (front.length < 2) return;
  final player = game.playerById(playerId);
  if (player == null) return;
  final heldByResource = <String, int>{};
  int heldFor(String tileKey) {
    final resourceId = resourceByTile[tileKey] ?? '';
    return heldByResource.putIfAbsent(
      resourceId,
      () => player.stockpile.quantityOf(resourceId),
    );
  }

  front.sort((a, b) {
    final c = heldFor(a).compareTo(heldFor(b));
    if (c != 0) return c;
    return a.compareTo(b);
  });
}

/// Orders improvable tiles for Development assign and work suggestions.
///
/// When [tileMapByRegion] and [topology] are supplied, uses the same
/// feedstock + connectivity-aware ordering as `suggestWorkOrders`. Otherwise
/// falls back to the SPEC simple comparator (connected → level → key).
List<String> orderDevelopmentImproveTiles({
  required Game game,
  required String playerId,
  required Iterable<String> tileKeys,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final list = tileKeys.toList();
  if (list.isEmpty) return list;

  if (tileMapByRegion == null ||
      tileMapByRegion.isEmpty ||
      topology == null) {
    return sortedDevelopmentImproveTileCandidates(
      tileKeys: list,
      connectedTileKeys: connectedTileKeys,
      tileState: tileState,
    );
  }

  final snapshot = buildConnectivityDevSnapshot(
    game: game,
    playerId: playerId,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
  if (snapshot == null) {
    return sortedDevelopmentImproveTileCandidates(
      tileKeys: list,
      connectedTileKeys: connectedTileKeys,
      tileState: tileState,
    );
  }

  var sorted = list..sort();
  sorted = prioritizeFeedstockBuildImprovementCandidates(
    game: game,
    playerId: playerId,
    sortedVisible: sorted,
  );
  return applyBuildImprovementConnectivityPreservingFeedstock(
    game: game,
    playerId: playerId,
    sortedVisible: sorted,
    snapshot: snapshot,
  );
}
