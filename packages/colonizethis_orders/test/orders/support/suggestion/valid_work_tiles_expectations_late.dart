part of 'valid_work_tiles_expectations.dart';

void vwtLateSuggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final exploreGame = fx.tribeConsulateGame('g1916e1');
  final exploreTopology = fx.topology();
  final explore = suggestedWorkOrders(
    game: exploreGame,
    topology: exploreTopology,
  ).where((o) => o.target == kWorkTargetExplore).toList();
  expect(explore, isNotEmpty);
  expect(
    explore.any(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isTrue,
  );
}

void vwtLateSuggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'gp2p',
    targetOwnerId: 'gp2',
  );
  final excludeGame = fx.game(
    id: 'g1916e2',
    players: [
      ValidWorkTilesTestSupport.defaultPlayer,
      const Player(id: 'gp2', displayName: 'P2', isHuman: false),
    ],
  );
  final excludeTopology = fx.topology();
  expect(
    suggestedWorkOrders(
      game: excludeGame,
      topology: excludeTopology,
    ).where((o) => o.target == kWorkTargetExplore).where(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isEmpty,
  );
}

void vwtLateSuggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  final fx = NwPartialRevealHomeTarget.tribeGrainIron();
  final prospectGame = fx.tribeConsulateGame('g1916p1');
  final prospectTopology = fx.topology();
  final prospect = suggestedWorkOrders(
    game: prospectGame,
    topology: prospectTopology,
  ).where((o) => o.target == kWorkTargetProspect).toList();
  expect(prospect, isNotEmpty);
  expect(prospect.any((o) => o.targetTileKey == fx.t1), isTrue);
}

void vwtLateSuggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  final ironFx = NwPartialRevealHomeTarget.tribeGrainIron(prospectedIron: true);
  expect(
    suggestedWorkOrders(
      game: ironFx.tribeConsulateGame('g1916p2'),
      topology: ironFx.topology(),
    ).where((o) => o.target == kWorkTargetProspect),
    isEmpty,
  );
}

void vwtLateSuggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final fx = NwPartialRevealHomeTarget.minorPurchase();
  expect(
    suggestedWorkOrders(
      game: fx.minorPurchaseGame(
        'g1916pl1',
        overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
      ),
      topology: fx.topology(),
    ).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isNotEmpty,
  );
}

void vwtLateSuggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  final purchaseFx = NwPartialRevealHomeTarget.minorPurchase();
  expect(
    suggestedWorkOrders(
      game: purchaseFx.minorPurchaseGame('g1916pl2'),
      topology: purchaseFx.topology(),
    ).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) ==
              purchaseFx.provTarget,
    ),
    isEmpty,
  );
}
