// Compact diplomacy-filter suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_diplomacy_filter_fixtures.dart';

/// Pins for diplomacy-filter scenario tables.
enum OrderSuggestionDiplomacyFilterTarget {
  matchesProjectionDerivedOwnerMapAcrossBothRegions,
  excludesUnownedNullOwnerProvinces,
  excludesEmptyStringOwnerProvinces,
  returnsOwnerByFullProvinceId,
  includesNewWorldProvinces,
  filterDoesNotDropCivilianMovesAtPeace,
  filterKeepsMoveToAtWarFaction,
}

void runOrderSuggestionDiplomacyFilterExpectation(
  OrderSuggestionDiplomacyFilterTarget target,
) {
  switch (target) {
    case OrderSuggestionDiplomacyFilterTarget
        .matchesProjectionDerivedOwnerMapAcrossBothRegions:
      final game = orderSuggestionDiplomacyFilterDualRegionGame();
      final cache = ProvinceOwnerCache.of(game.worldState);
      final expected = <String, String>{
        for (final ownerId in cache.ownerIds)
          for (final p in cache.provincesOwnedBy(ownerId)) p.id: ownerId,
      };

      final map = getProvinceOwnerMap(game);

      expect(map, expected);
      expect(map, {
        'oldWorld|p1': 'gp1',
        'newWorld|n1': 'gp1',
        'oldWorld|p2': 'gp2',
      });

    case OrderSuggestionDiplomacyFilterTarget.excludesUnownedNullOwnerProvinces:
      final map = getProvinceOwnerMap(
        orderSuggestionDiplomacyFilterDualRegionGame(),
      );
      expect(map.containsKey('oldWorld|p3'), isFalse);

    case OrderSuggestionDiplomacyFilterTarget.excludesEmptyStringOwnerProvinces:
      final map = getProvinceOwnerMap(
        orderSuggestionDiplomacyFilterEmptyStringOwnerGame(),
      );
      expect(map, {'oldWorld|p1': 'gp1'});
      expect(map.containsKey('oldWorld|p2'), isFalse);

    case OrderSuggestionDiplomacyFilterTarget.returnsOwnerByFullProvinceId:
      final map = getProvinceOwnerMap(
        orderSuggestionDiplomacyFilterOldWorldTwoGpGame(),
      );
      expect(map['oldWorld|p1'], 'gp1');
      expect(map['oldWorld|p2'], 'gp2');

    case OrderSuggestionDiplomacyFilterTarget.includesNewWorldProvinces:
      final map = getProvinceOwnerMap(
        orderSuggestionDiplomacyFilterNewWorldTwoGpGame(),
      );
      expect(map['newWorld|n1'], 'gp1');
      expect(map['newWorld|n2'], 'gp2');

    case OrderSuggestionDiplomacyFilterTarget
        .filterDoesNotDropCivilianMovesAtPeace:
      final game = orderSuggestionDiplomacyFilterPeacefulTwoGpGame();
      final orders = [
        MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered, orders);

    case OrderSuggestionDiplomacyFilterTarget.filterKeepsMoveToAtWarFaction:
      final game = orderSuggestionDiplomacyFilterAtWarTwoGpGame();
      final orders = [
        MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered.length, 1);
      expect(filtered.first.destinationTileKey, 'oldWorld|p2|0|0');
  }
}
