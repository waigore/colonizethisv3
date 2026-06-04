part of 'order_suggestion_work.dart';

void _addWorkerSuggestionsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String playerId,
  required Unit unit,
  required String type,
  required String unitRegionId,
  required String atProvinceId,
  required Map<String, Set<String>> existingTargetsByUnit,
  required Map<String, List<String>> visibleCandidatesSortedByWorkTarget,
  required Set<String> playerOwnedProvinceIds,
  required Set<String> devExclusiveReservedTiles,
  required List<WorkOrder> suggestions,
  required IncrementalCandidateValidator candidateValidator,
  required DiplomacyFactionMembership factionMembership,
  required WorkSuggestionProbeBudget workProbeBudget,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final allowedTargets = workOrderTargetsByUnitType[type];
  if (allowedTargets == null) return;

  for (final target in allowedTargets) {
    final sortedVisible = visibleCandidatesSortedByWorkTarget.putIfAbsent(
      target,
      () {
        final raw = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: target,
          tileMapByRegion: tileMapByRegion,
          playerOwnedProvinceIds: playerOwnedProvinceIds,
          factionMembership: factionMembership,
        );
        final visible = sortedVisibleWorkTargetCandidates(view, raw);
        if (target == kWorkTargetBuildImprovement) {
          return _prioritizeFeedstockBuildImprovementCandidates(
            game: game,
            playerId: playerId,
            sortedVisible: visible,
          );
        }
        return visible;
      },
    );

    WorkSuggestionPipeline.run(
      unit: unit,
      unitType: type,
      unitRegionId: unitRegionId,
      atProvinceId: atProvinceId,
      workTarget: target,
      existingTargetsByUnit: existingTargetsByUnit,
      suggestions: suggestions,
      noCandidateReason: 'no_valid_tile',
      candidatesProvider: () sync* {
        for (final tk in sortedVisible) {
          if (isDevExclusiveWorkTarget(target) &&
              devExclusiveReservedTiles.contains(tk)) {
            continue;
          }
          yield WorkOrder(unitId: unit.id, target: target, targetTileKey: tk);
        }
      },
      candidateAcceptor: (candidate) {
        return isWorkOrderAcceptedWithValidator(candidateValidator, candidate);
      },
      probeBudget: workProbeBudget,
    );
  }
}

/// Refs #2847 § H8-extraction: when [playerId]'s feedstock-extraction gate is
/// active ([feedstockExtractionResourceIdsForPlayer] non-empty), stable-
/// partitions the lexicographically-sorted `build_improvement` candidates so
/// tiles hosting an unimproved feedstock resource sort ahead of the rest.
///
/// The worker suggestion pipeline emits only the **first accepted**
/// `build_improvement` candidate per Builder ([WorkSuggestionPipeline.run]
/// with `includeAllAccepted: false`), so without this reordering the lone
/// suggested tile is whichever sorts first lexicographically — rarely the
/// feedstock tile. The downstream
/// [kRegimentBuildInputFeedstockExtractionScoreBoost] in
/// `selectFullAiCivilianWorkOrders` can only re-rank suggestions that exist,
/// so the boost is inert unless the feedstock tile is actually suggested. This
/// puts unimproved feedstock tiles first so the emitted suggestion targets the
/// tile the boost is meant to select.
///
/// Off-gate (empty feedstock set) or when no candidate is an unimproved
/// feedstock tile, returns [sortedVisible] unchanged so ordinary players and
/// targets keep their existing deterministic ordering. The promoted feedstock
/// partition is then ordered by [_orderFeedstockFrontByCoAvailability] so the
/// least-held feedstock (the missing co-feedstock of a multi-input improvement
/// recipe) is suggested first; the non-feedstock partition keeps its
/// lexicographic order. Pure over `(game, playerId, sortedVisible)`.
List<String> _prioritizeFeedstockBuildImprovementCandidates({
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

/// Refs #2847 § H8-extraction feedstock co-availability: orders the unimproved
/// feedstock `build_improvement` [front] partition so a tile hosting the
/// feedstock resource the player currently holds the **least** of sorts first,
/// lexicographically tie-broken.
///
/// Multi-input improvement recipes (`castIron_from_timber_iron_coal` consumes
/// `timber` **and** `iron`) only become feasible once every feedstock is on
/// hand, but the worker pipeline emits a single `build_improvement` suggestion
/// per Builder per pass. With a purely lexicographic front the lone suggestion
/// always targets the lex-first feedstock resource (e.g. `timber`), so a
/// Builder keeps extracting the feedstock it already holds while the missing
/// co-feedstock (`iron`) is never suggested and the multi-input recipe stays
/// infeasible (`feasibleRuns == 0`) indefinitely — the seed-42 supplier holds
/// `timber` but `iron` stays `0`. Biasing the front toward the least-held
/// feedstock routes the Builder onto the missing co-feedstock, driving the
/// stockpile toward the co-availability the production-layer reservation
/// (`economy_planner.dart` § Improvement-input feedstock co-availability
/// reservation) then protects.
///
/// Pure and deterministic over `(game, playerId, front)`: the sort key is
/// `(player-held quantity of the tile's feedstock resource ascending, tile key
/// ascending)`, so identical inputs yield identical ordering and ties fall back
/// to the existing lexicographic order. When the player is unknown or every
/// feedstock tile hosts an equally-held resource, the lexicographic order is
/// preserved.
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
