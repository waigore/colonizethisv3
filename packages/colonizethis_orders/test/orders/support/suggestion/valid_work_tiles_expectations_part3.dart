part of 'valid_work_tiles_expectations.dart';

void _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
    resourceByTileKey: {keys.t0: 'grain', keys.t1: 'iron'},
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {keys.t1},
    },
  );
  final game = fx.game(
    id: 'g1916p2',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) => o.target == kWorkTargetProspect,
    ),
    isEmpty,
  );
}

void _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
    resourceByTileKey: {keys.t1: 'grain'},
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: fx.provHome,
    tileKey: fx.tileHome,
  );
  final game = fx.game(
    id: 'g1916pl1',
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
    unit: unit,
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isNotEmpty,
  );
}

void _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
    resourceByTileKey: {keys.t1: 'grain'},
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: fx.provHome,
    tileKey: fx.tileHome,
  );
  final game = fx.game(
    id: 'g1916pl2',
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    unit: unit,
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isEmpty,
  );
}
