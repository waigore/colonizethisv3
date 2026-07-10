// Compact valid-work-tiles expectation shorthands (Refs #3949 slice 20).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';

void vwtExpectKeysEmpty(
  Game game,
  String unitId,
  String workTarget, {
  bool withVisibility = false,
}) {
  final keys = withVisibility
      ? vwtVisKeys(game, unitId, workTarget)
      : vwtPlainKeys(game, unitId, workTarget);
  expect(keys, isEmpty);
}

void vwtExpectBuildVisMembership(
  Game game, {
  required Iterable<String> included,
  Iterable<String> excluded = const [],
}) {
  final valid = vwtVisKeys(game, 'u1', kWorkTargetBuildImprovement);
  for (final tile in included) {
    expect(valid.contains(tile), isTrue);
  }
  for (final tile in excluded) {
    expect(valid.contains(tile), isFalse);
  }
}

void vwtExpectPartialRevealSuggestions({
  required NwPartialRevealHomeTarget fx,
  required Game game,
  required String workTarget,
  required bool expectNonEmpty,
  String? provinceId,
  String? tileKey,
}) {
  var orders = suggestedWorkOrders(
    game: game,
    topology: fx.topology(),
  ).where((o) => o.target == workTarget).toList();
  if (provinceId != null) {
    orders = orders
        .where((o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provinceId)
        .toList();
  }
  if (tileKey != null && expectNonEmpty) {
    expect(orders.any((o) => o.targetTileKey == tileKey), isTrue);
    return;
  }
  expect(orders, expectNonEmpty ? isNotEmpty : isEmpty);
}

void vwtExpectProspectVisExcludesAll(
  Game game,
  Iterable<String> tiles, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: owSingleProvinceTopology('p1'),
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
    tileMapByRegion: tileMapByRegion,
  );
  for (final tile in tiles) {
    expect(valid.contains(tile), isFalse);
  }
}

String vwtTk(String local, int x, int y) =>
    ValidWorkTilesTestSupport.tileKey(local, x, y);

String vwtPid(String local) => ValidWorkTilesTestSupport.provinceId(local);

void vwtExpectExploreVisMembership(
  Game game, {
  required Iterable<String> included,
  required Iterable<String> excluded,
}) {
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  for (final tile in included) {
    expect(valid, contains(tile));
  }
  for (final tile in excluded) {
    expect(valid, isNot(contains(tile)));
  }
}

void vwtExpectExploreLatencyUnder1s() {
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: owTribeExploreLatencyGame(),
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(1000));
}

void vwtExpectNoMoveToOtherGpProvince() {
  final fx = owGpAdjacentMoveFixture();
  final suggestions = suggestMoveOrders(
    buildPlayerView(
      fx.game,
      fx.topology,
      ValidWorkTilesTestSupport.playerId,
    ),
    fx.game,
    fx.topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (m) =>
          Unit.provinceIdFromTileKey(m.destinationTileKey) ==
          fx.otherGpProvinceId,
    ),
    isEmpty,
  );
}

void vwtExpectBuildSuggestionsSorted(List<String> tileKeys) {
  final buildSuggestions = suggestedWorkOrders(
    game: owGrainBuildSuggestGame(tileKeys: tileKeys),
    topology: owSingleProvinceTopology('p1'),
  ).where((o) => o.target == kWorkTargetBuildImprovement).toList();
  if (buildSuggestions.length > 1) {
    for (var i = 0; i < buildSuggestions.length - 1; i++) {
      expect(
        buildSuggestions[i].targetTileKey.compareTo(
          buildSuggestions[i + 1].targetTileKey,
        ),
        lessThanOrEqualTo(0),
      );
    }
  }
}

void vwtExpectBuildExcludesReservedTile(String reserved, String other) {
  expect(
    suggestedWorkOrders(
      game: owGrainBuildSuggestGame(tileKeys: [reserved, other]),
      topology: owSingleProvinceTopology('p1'),
      currentOrders: Orders(
        workOrdersByPlayerId: {
          ValidWorkTilesTestSupport.playerId: [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: reserved,
            ),
          ],
        },
      ),
    ).where(
      (o) =>
          o.target == kWorkTargetBuildImprovement &&
          o.targetTileKey == reserved,
    ),
    isEmpty,
  );
}

void vwtExpectMineralProspectGate() {
  final grain = vwtTk('p1', 0, 0);
  final iron = vwtTk('p1', 1, 0);
  final p1 = vwtPid('p1');
  final provinces = [vwtOwnedProvince('p1')];
  final tiles = {
    p1: [grain, iron],
  };
  final resources = {grain: 'grain', iron: 'iron'};
  final improvements = {grain: 0, iron: 0};
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grain,
      improvementByTile: improvements,
    ),
    included: [grain],
    excluded: [iron],
  );
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grain,
      improvementByTile: improvements,
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {iron},
      },
    ),
    included: [grain, iron],
  );
}
