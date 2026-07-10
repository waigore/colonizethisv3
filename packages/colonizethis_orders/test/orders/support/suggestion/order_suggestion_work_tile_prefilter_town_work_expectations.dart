// Town-work prefilter assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/work_tile_candidacy/work_tile_candidacy.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_suggestion_work_tile_prefilter_town_work_fixtures.dart';

/// Pins for [orderSuggestionWorkTilePrefilterTownWorkScenarios] rows.
enum OrderSuggestionWorkTilePrefilterTownWorkTarget {
  upgradeTownOwnedOnly,
  buildFortMatchesUpgradeTown,
  defaultPathUsesProvinceOwnerCache,
}

void runOrderSuggestionWorkTilePrefilterTownWorkExpectation(
  OrderSuggestionWorkTilePrefilterTownWorkTarget target,
) {
  switch (target) {
    case OrderSuggestionWorkTilePrefilterTownWorkTarget.upgradeTownOwnedOnly:
      const ownedTownTile = 'oldWorld|p1|0|0';
      const otherTownTile = 'oldWorld|p2|0|0';
      final game = workTilePrefilterOwnedTownGame(
        ownedTownTile: ownedTownTile,
        otherTownTile: otherTownTile,
      );

      final tiles = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: workTilePrefilterTownPlayerId,
        workTarget: kWorkTargetUpgradeTown,
        playerOwnedProvinceIds: {'$workTilePrefilterTownOldWorld|p1'},
      );

      expect(tiles, equals({ownedTownTile}));
      expect(tiles, isNot(contains(otherTownTile)));

    case OrderSuggestionWorkTilePrefilterTownWorkTarget.buildFortMatchesUpgradeTown:
      const townTile = 'oldWorld|p1|0|0';
      final game = workTilePrefilterSingleTownGame(townTile: townTile);
      const owned = {'$workTilePrefilterTownOldWorld|p1'};

      final upgradeTiles = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: workTilePrefilterTownPlayerId,
        workTarget: kWorkTargetUpgradeTown,
        playerOwnedProvinceIds: owned,
      );
      final fortTiles = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: workTilePrefilterTownPlayerId,
        workTarget: kWorkTargetBuildFort,
        playerOwnedProvinceIds: owned,
      );

      expect(fortTiles, upgradeTiles);
      expect(fortTiles, equals({townTile}));

    case OrderSuggestionWorkTilePrefilterTownWorkTarget
        .defaultPathUsesProvinceOwnerCache:
      const ownedTownTile = 'oldWorld|p1|0|0';
      const otherTownTile = 'oldWorld|p2|0|0';
      final game = workTilePrefilterCacheGame(
        ownedTownTile: ownedTownTile,
        otherTownTile: otherTownTile,
      );
      final cacheOwnedIds = <String>{
        for (final p in ProvinceOwnerCache.of(
          game.worldState,
        ).provincesOwnedBy(workTilePrefilterTownPlayerId))
          p.id,
      };
      final fallback = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: workTilePrefilterTownPlayerId,
        workTarget: kWorkTargetUpgradeTown,
      );
      final suppliedFromCache = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: workTilePrefilterTownPlayerId,
        workTarget: kWorkTargetUpgradeTown,
        playerOwnedProvinceIds: cacheOwnedIds,
      );
      expect(fallback, suppliedFromCache);
      expect(cacheOwnedIds, equals({'$workTilePrefilterTownOldWorld|p1'}));
      expect(fallback, equals({ownedTownTile}));
  }
}
