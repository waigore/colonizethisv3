part of 'valid_work_tiles_expectation_shorthand.dart';


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

List<WorkOrder> vwtPartialRevealSuggestions(
  NwPartialRevealHomeTarget fx,
  Game game,
  String workTarget,
) =>
    suggestedWorkOrders(game: game, topology: fx.topology())
        .where((o) => o.target == workTarget)
        .toList();

void vwtExpectPartialRevealSuggestions({
  required NwPartialRevealHomeTarget fx,
  required Game game,
  required String workTarget,
  required bool expectNonEmpty,
  String? provinceId,
  String? tileKey,
}) {
  var orders = vwtPartialRevealSuggestions(fx, game, workTarget);
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

Set<String> vwtProspectVisKeys(
  Game game, {
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    validWorkTilesWithVisibility(
      game: game,
      topology: owSingleProvinceTopology('p1'),
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      tileMapByRegion: tileMapByRegion,
    );

void vwtExpectProspectVisContains(
  Game game,
  String tile, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expect(vwtProspectVisKeys(game, tileMapByRegion: tileMapByRegion), contains(tile));
}

void vwtExpectProspectVisExcludesAll(
  Game game,
  Iterable<String> tiles, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final valid = vwtProspectVisKeys(game, tileMapByRegion: tileMapByRegion);
  for (final tile in tiles) {
    expect(valid.contains(tile), isFalse);
  }
}

void vwtExpectMineralBuildVisBeforeAfterProspect() {
  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final provinces = [vwtOwnedProvince('p1')];
  final tiles = {p1: [grainTile, ironTile]};
  final resources = {grainTile: 'grain', ironTile: 'iron'};
  final improvements = {grainTile: 0, ironTile: 0};
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grainTile,
      improvementByTile: improvements,
    ),
    included: [grainTile],
    excluded: [ironTile],
  );
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grainTile,
      improvementByTile: improvements,
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {ironTile},
      },
    ),
    included: [grainTile, ironTile],
  );
}
