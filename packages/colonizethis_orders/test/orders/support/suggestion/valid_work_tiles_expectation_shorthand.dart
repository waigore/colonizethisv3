// Compact valid-work-tiles expectation shorthands (Refs #3949 slice 20).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';

NwPartialRevealHomeTarget vwtTribePartialFx({
  Map<String, String> resourceByTileKey = const {},
  Map<String, Set<String>> playerProspectedTiles = const {},
}) =>
    NwPartialRevealHomeTarget(
      homeLocalId: 'home',
      targetLocalId: 'tribe1',
      targetOwnerId: 'tribe1',
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: playerProspectedTiles,
    );

NwPartialRevealHomeTarget vwtTribeGrainIronFx({bool prospectedIron = false}) {
  final base = vwtTribePartialFx();
  return vwtTribePartialFx(
    resourceByTileKey: {base.t0: 'grain', base.t1: 'iron'},
    playerProspectedTiles: prospectedIron
        ? {ValidWorkTilesTestSupport.playerId: {base.t1}}
        : const {},
  );
}

Game vwtTribeConsulateGame(NwPartialRevealHomeTarget fx, {required String id}) =>
    fx.game(
      id: id,
      tribes: const [ValidWorkTilesTestSupport.defaultTribe],
      overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    );

NwPartialRevealHomeTarget vwtMinorPurchaseFx({
  Map<String, String> resourceByTileKey = const {},
}) {
  final base = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
  );
  return NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
    resourceByTileKey: resourceByTileKey.isEmpty
        ? {base.t1: 'grain'}
        : resourceByTileKey,
  );
}

Game vwtMinorPurchaseGame(
  NwPartialRevealHomeTarget fx, {
  required String id,
  List<OvertureState>? overtureStates,
}) =>
    fx.game(
      id: id,
      players: [ValidWorkTilesTestSupport.playerWithTreasury()],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      overtureStates: overtureStates,
      unit: Unit(
        id: 'u1',
        type: kUnitTypeMerchant,
        ownerId: ValidWorkTilesTestSupport.playerId,
        locationProvinceId: fx.provHome,
        tileKey: fx.tileHome,
      ),
    );

Iterable<WorkOrder> vwtSuggestExplore(Game game, MapTopology topology) =>
    suggestedWorkOrders(game: game, topology: topology).where(
      (o) => o.target == kWorkTargetExplore,
    );

Iterable<WorkOrder> vwtSuggestProspect(Game game, MapTopology topology) =>
    suggestedWorkOrders(game: game, topology: topology).where(
      (o) => o.target == kWorkTargetProspect,
    );

Iterable<WorkOrder> vwtSuggestPurchaseLand(
  Game game,
  MapTopology topology,
  String targetProvinceId,
) =>
    suggestedWorkOrders(game: game, topology: topology).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == targetProvinceId,
    );

void vwtExpectVisProspectContains(
  Game game,
  MapTopology topology,
  String tile, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expect(
    validWorkTilesWithVisibility(
      game: game,
      topology: topology,
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      tileMapByRegion: tileMapByRegion,
    ),
    contains(tile),
  );
}

void vwtExpectVisProspectExcludes(
  Game game,
  MapTopology topology,
  String tile, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expect(
    validWorkTilesWithVisibility(
      game: game,
      topology: topology,
      unitId: 'u1',
      workTarget: kWorkTargetProspect,
      tileMapByRegion: tileMapByRegion,
    ).contains(tile),
    isFalse,
  );
}

void vwtExpectVisExplore({
  required Game game,
  required MapTopology topology,
  required Iterable<String> includedTiles,
  Iterable<String> excludedTiles = const [],
}) {
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  for (final tile in includedTiles) {
    expect(valid, contains(tile));
  }
  for (final tile in excludedTiles) {
    expect(valid, isNot(contains(tile)));
  }
}

void vwtExpectVisExploreLatencyUnder({
  required Game game,
  required MapTopology topology,
  int maxMs = 1000,
}) {
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(maxMs));
}

void vwtExpectNoMovesToProvince(
  Game game,
  MapTopology topology,
  String provinceId,
) {
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (m) => Unit.provinceIdFromTileKey(m.destinationTileKey) == provinceId,
    ),
    isEmpty,
  );
}

void vwtExpectBuildSuggestionsSorted(List<String> tileKeys) {
  final game = owGrainBuildSuggestGame(tileKeys: tileKeys);
  final topology = owSingleProvinceTopology('p1');
  final buildSuggestions = suggestedWorkOrders(game: game, topology: topology)
      .where((o) => o.target == kWorkTargetBuildImprovement)
      .toList();
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

void vwtExpectNoBuildSuggestionForReservedTile({
  required List<String> tileKeys,
  required String reservedTile,
}) {
  final game = owGrainBuildSuggestGame(tileKeys: tileKeys);
  final topology = owSingleProvinceTopology('p1');
  final buildSuggestions = suggestedWorkOrders(
    game: game,
    topology: topology,
    currentOrders: Orders(
      workOrdersByPlayerId: {
        ValidWorkTilesTestSupport.playerId: [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: reservedTile,
          ),
        ],
      },
    ),
  ).where(
    (o) =>
        o.target == kWorkTargetBuildImprovement && o.targetTileKey == reservedTile,
  );
  expect(buildSuggestions, isEmpty);
}
