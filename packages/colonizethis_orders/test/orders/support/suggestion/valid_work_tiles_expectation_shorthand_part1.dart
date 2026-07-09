part of 'valid_work_tiles_expectation_shorthand.dart';


NwPartialRevealHomeTarget vwtTribeGrainIronFx({bool prospectedIron = false}) {
  final base = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  return NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
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
  final valid = vwtBuildVisKeys(game);
  for (final tile in included) {
    expect(valid.contains(tile), isTrue);
  }
  for (final tile in excluded) {
    expect(valid.contains(tile), isFalse);
  }
}
