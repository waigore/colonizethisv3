// Table-driven diplomacy-filter suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_diplomacy_filter_fixtures.dart';

void osdfRunMatchesProjectionDerivedOwnerMapAcrossBothRegions() {
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
}

void osdfRunExcludesUnownedNullOwnerProvinces() {
  final map = getProvinceOwnerMap(
    orderSuggestionDiplomacyFilterDualRegionGame(),
  );
  expect(map.containsKey('oldWorld|p3'), isFalse);
}

void osdfRunExcludesEmptyStringOwnerProvinces() {
  final map = getProvinceOwnerMap(
    orderSuggestionDiplomacyFilterEmptyStringOwnerGame(),
  );
  expect(map, {'oldWorld|p1': 'gp1'});
  expect(map.containsKey('oldWorld|p2'), isFalse);
}

void osdfRunReturnsOwnerByFullProvinceId() {
  final map = getProvinceOwnerMap(
    orderSuggestionDiplomacyFilterOldWorldTwoGpGame(),
  );
  expect(map['oldWorld|p1'], 'gp1');
  expect(map['oldWorld|p2'], 'gp2');
}

void osdfRunIncludesNewWorldProvinces() {
  final map = getProvinceOwnerMap(
    orderSuggestionDiplomacyFilterNewWorldTwoGpGame(),
  );
  expect(map['newWorld|n1'], 'gp1');
  expect(map['newWorld|n2'], 'gp2');
}

void osdfRunFilterDoesNotDropCivilianMovesAtPeace() {
  final game = orderSuggestionDiplomacyFilterPeacefulTwoGpGame();
  final orders = [
    MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
  ];
  final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
  expect(filtered, orders);
}

void osdfRunFilterKeepsMoveToAtWarFaction() {
  final game = orderSuggestionDiplomacyFilterAtWarTwoGpGame();
  final orders = [
    MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
  ];
  final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
  expect(filtered.length, 1);
  expect(filtered.first.destinationTileKey, 'oldWorld|p2|0|0');
}

List<RunnableScenario> getProvinceOwnerMapProvinceOwnerCacheScenarios() =>
    const [
      rs('matches the projection-derived owner map across both regions', osdfRunMatchesProjectionDerivedOwnerMapAcrossBothRegions),
      rs('excludes unowned (null-owner) provinces', osdfRunExcludesUnownedNullOwnerProvinces),
      rs('excludes empty-string owner provinces (isNotEmpty parity)', osdfRunExcludesEmptyStringOwnerProvinces),
    ];

List<RunnableScenario> filterMoveOrdersByDiplomacyScenarios() => const [
  rs('getProvinceOwnerMap returns owner by full province id', osdfRunReturnsOwnerByFullProvinceId),
  rs('getProvinceOwnerMap includes newWorld provinces', osdfRunIncludesNewWorldProvinces),
  rs('filterMoveOrdersByDiplomacy does not drop civilian moves at peace', osdfRunFilterDoesNotDropCivilianMovesAtPeace),
  rs('filterMoveOrdersByDiplomacy keeps move to at-war faction', osdfRunFilterKeepsMoveToAtWarFaction),
];
