// Scenario run tear-offs for order_suggestion_army_move (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_army_move_fixtures.dart';

void osamRunIncludesCrossRegionOwnedDestination() {
  final game = armyMoveGame0();
  final topology = armyMoveTopology0();
  final view = buildPlayerView(game, topology, armyMoveGp);
  final suggestions = suggestArmyMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.any(
      (s) => s.armyId == 'field_a' && s.destinationProvinceId == armyMoveNw,
    ),
    isTrue,
  );
}

void osamRunPlayerViewOwnedCacheMatchesLegacyScan() {
  final game = armyMoveGame0();
  final topology = armyMoveTopology0();
  final view = buildPlayerView(game, topology, armyMoveGp);
  final army = armyMoveFieldArmy(game);
  final ownedFromView = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == armyMoveGp) e.key,
  };
  final withoutCache = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: armyMoveGp,
    army: army,
  );
  final withCache = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: armyMoveGp,
    army: army,
    playerOwnedFullProvinceIds: ownedFromView,
  );
  expect(withCache, withoutCache);
}

void osamRunFallbackOwnedScanFromProvinceOwnerCache() {
  final game = armyMoveGame0();
  final topology = armyMoveTopology0();
  final army = armyMoveFieldArmy(game);
  final cacheOwned = <String>{
    for (final p in ProvinceOwnerCache.of(
      game.worldState,
    ).provincesOwnedBy(armyMoveGp))
      toFullProvinceId(p.regionId, p.id),
  };
  final fallback = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: armyMoveGp,
    army: army,
  );
  final suppliedFromCache = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: armyMoveGp,
    army: army,
    playerOwnedFullProvinceIds: cacheOwned,
  );
  expect(fallback, suppliedFromCache);
  expect(cacheOwned, contains(armyMoveNw));
  expect(fallback, contains(armyMoveNw));
}

void osamRunFallbackNoOwnedWhenCacheEmptyForPlayer() {
  final game = armyMoveGame0();
  final topology = armyMoveTopology0();
  final army = armyMoveFieldArmy(game);
  const foreign = 'gpX';
  expect(
    ProvinceOwnerCache.of(game.worldState).provincesOwnedBy(foreign),
    isEmpty,
  );
  final fallback = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: foreign,
    army: army,
  );
  expect(fallback, isEmpty);
}

void osamRunStillProposesAlternateWhenDraftHasPriorMove() {
  final game = armyMoveGameWithPriorMoveToP2();
  final topology = armyMoveTopology0(includeP2: true);
  final view = buildPlayerView(game, topology, armyMoveGp);
  final current = Orders(
    armyMoveOrdersByPlayerId: {
      armyMoveGp: [
        ArmyMoveOrder(armyId: 'field_a', destinationProvinceId: armyMoveP2),
      ],
    },
  );
  final suggestions = suggestArmyMoveOrders(view, game, topology, current);
  expect(
    suggestions.any((s) => s.destinationProvinceId == armyMoveNw),
    isTrue,
    reason:
        'replacement-aware validation should allow other owned destinations',
  );
}

void osamRunCachedOwnedSetMatchesDefaultAllProvincesScan() {
  final game = armyMoveDestIdsGame();
  final topology = armyMoveDestIdsTopology();
  final army = game.worldState.armies.first;
  final uncached = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: armyMoveGp,
    army: army,
  );
  final owned = <String>{
    for (final p in allProvinces(game.worldState))
      if (p.ownerId == armyMoveGp) toFullProvinceId(p.regionId, p.id),
  };
  final cached = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: armyMoveGp,
    army: army,
    playerOwnedFullProvinceIds: owned,
  );
  expect(cached, uncached);
}
