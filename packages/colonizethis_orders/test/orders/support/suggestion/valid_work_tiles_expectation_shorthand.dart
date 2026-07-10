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
  var orders = suggestedWorkOrders(game: game, topology: fx.topology())
      .where((o) => o.target == workTarget)
      .toList();
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
