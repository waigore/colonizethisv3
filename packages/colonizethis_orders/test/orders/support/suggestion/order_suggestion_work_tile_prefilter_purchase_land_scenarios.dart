// Table-driven purchase_land prefilter scenarios (Refs #3949 wave 3).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/work_tile_candidacy/work_tile_candidacy.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../scenario_runner.dart';
import 'order_suggestion_work_tile_prefilter_purchase_land_fixtures.dart';

void oswtplRunIncludesMinorExcludesGpOwned() {
  const minorTile = 'oldWorld|minor1|0|0';
  const gpTile = 'oldWorld|p1|0|0';
  final game = workTilePrefilterMinorGpGame(
    minorTile: minorTile,
    gpTile: gpTile,
  );

  final tiles = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: workTilePrefilterPlayerId,
    workTarget: kWorkTargetPurchaseLand,
  );

  expect(tiles, contains(minorTile));
  expect(tiles, isNot(contains(gpTile)));

  final membership = DiplomacyFactionMembership.from(game);
  final tilesWithExplicitMembership = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: workTilePrefilterPlayerId,
    workTarget: kWorkTargetPurchaseLand,
    factionMembership: membership,
  );
  expect(tilesWithExplicitMembership, tiles);
}

void oswtplRunIncludesTribeOwnedProvinces() {
  const tribeTile = 'oldWorld|tribe1|0|0';
  final game = workTilePrefilterTribeGame(tribeTile: tribeTile);

  final tiles = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: workTilePrefilterPlayerId,
    workTarget: kWorkTargetPurchaseLand,
  );

  expect(tiles, contains(tribeTile));
}

void oswtplRunPlayerOwnedProvinceIdsMatchesDefaultPath() {
  const minorTile = 'oldWorld|minor1|0|0';
  const gpTile = 'oldWorld|p1|0|0';
  final game = workTilePrefilterBuildRoadGame(
    minorTile: minorTile,
    gpTile: gpTile,
  );

  final defaultTiles = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: workTilePrefilterPlayerId,
    workTarget: kWorkTargetBuildRoad,
  );
  final owned = <String>{
    for (final p in allProvinces(game.worldState))
      if (p.ownerId == workTilePrefilterPlayerId) p.id,
  };
  final explicitTiles = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: workTilePrefilterPlayerId,
    workTarget: kWorkTargetBuildRoad,
    playerOwnedProvinceIds: owned,
  );
  expect(explicitTiles, defaultTiles);
}

List<RunnableScenario>
orderSuggestionWorkTilePrefilterPurchaseLandScenarios() => const [
  RunnableScenario(
    label:
        'includes resource tiles in minor-owned provinces, excludes GP-owned',
    run: oswtplRunIncludesMinorExcludesGpOwned,
  ),
  RunnableScenario(
    label: 'includes resource tiles in tribe-owned provinces',
    run: oswtplRunIncludesTribeOwnedProvinces,
  ),
  RunnableScenario(
    label:
        'playerOwnedProvinceIds yields same candidates as internal scan (build_road)',
    run: oswtplRunPlayerOwnedProvinceIdsMatchesDefaultPath,
  ),
];
