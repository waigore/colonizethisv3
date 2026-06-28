part of 'game_setup_create.dart';

Game _buildInitialGame({
  required GameSetupConfig config,
  required String gameId,
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
  required double initialMapZoomMultiplier,
}) {
  final worldState = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: oldWorldProvinces),
    newWorld: RegionData(provinces: newWorldProvinces),
  );
  final baseStockpileQuantities = _buildInitialStockpileQuantities(config);
  final humanSlots = config.humanGreatPowerSlotIndices;
  final players = <Player>[
    for (var i = 0; i < gpIds.length; i++)
      Player(
        id: gpIds[i],
        displayName: 'Power ${i + 1}',
        isHuman: humanSlots.contains(i),
        stockpile: Stockpile(
          quantities: baseStockpileQuantities.isEmpty
              ? const {}
              : Map<CommodityId, int>.from(baseStockpileQuantities),
        ),
        workerPool: WorkerPool(
          peasants: config.startingResources.initialPeasants,
        ),
        treasury: config.startingResources.initialTreasury,
        techUnlocked: const {},
      ),
  ];
  final minorNations = <MinorNation>[
    for (var i = 0; i < minorIds.length; i++)
      MinorNation(id: minorIds[i], displayName: 'Minor ${i + 1}'),
  ];
  final tribes = <Tribe>[
    for (var i = 0; i < tribeIds.length; i++)
      Tribe(id: tribeIds[i], displayName: 'Tribe ${i + 1}'),
  ];
  final diplomacyRelations = _buildInitialDiplomacyRelations(
    gpIds: gpIds,
    minorIds: minorIds,
    tribeIds: tribeIds,
  );
  final aiControlByGpId = {for (final p in players) p.id: !p.isHuman};
  return Game(
    id: gameId,
    worldState: worldState,
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    turnTimeMapping: TurnTimeMapping.gdd01,
    diplomacyRelations: diplomacyRelations,
    aiControlByGpId: aiControlByGpId,
    capitalTileGrainBonusPerTurn:
        config.startingResources.capitalTileGrainBonusPerTurn,
    mapViewState: MapViewState.defaults.copyWith(
      zoomMultiplier: initialMapZoomMultiplier,
    ),
    infiniteMode: config.infiniteMode,
    worldMarketState: WorldMarketState.withDefaultPrices(
      _buildInitialMarketPrices(),
    ),
  );
}

/// Builds the initial integer market-price map seeded from
/// `ResourceRules.defaultRules.defaultMarketPriceForCommodityId` for every
/// tradeable commodity, per `SPEC/game/world-market.md` § Tradeable
/// commodities and § Initial price seeding.
///
/// Tradeable = every `CommodityCatalog.all` entry **except** the riches set
/// (`gold`, `silver`, `gems`, `diamonds`, `spices`). Riches auto-convert to
/// treasury in phase 3 and are excluded from the world market entirely.
///
/// Used by [_buildInitialGame] to populate `Game.worldMarketState.prices`
/// at game start (per #3093 § Price presentation & data model) so the
/// Trade screen never has to fall back to the canonical em-dash glyph
/// for a tradeable commodity and the validator / AI treasury planner can
/// resolve a finite integer price on turn 1. The catalog default already
/// covers every tradeable id (raw-resource entries in
/// `ResourceRules.defaultMarketPrice` plus the input-cost-derived
/// manufactured base prices), so the returned map has exactly one entry
/// per tradeable commodity (22 today: 2 food + 11 raw materials + 9
/// manufactured).
Map<CommodityId, int> _buildInitialMarketPrices() {
  final rules = ResourceRules.defaultRules;
  final result = <CommodityId, int>{};
  for (final commodity in CommodityCatalog.all) {
    if (commodity.category == CommodityCategory.riches) continue;
    if (commodity.id == 'spices') continue;
    final price = rules.defaultMarketPriceForCommodityId(commodity.id);
    if (price != null) {
      result[commodity.id] = price;
    }
  }
  return result;
}

Map<CommodityId, int> _buildInitialStockpileQuantities(GameSetupConfig config) {
  final startingResources = config.startingResources;
  final initialGrainQuantity =
      startingResources.initialPeasants * startingResources.initialGrainTurns;
  final out = <CommodityId, int>{};
  if (initialGrainQuantity > 0) {
    out[CommodityCatalog.grain.id] = initialGrainQuantity;
  }
  if (startingResources.initialImprovementSlots > 0) {
    final slots = startingResources.initialImprovementSlots;
    out[CommodityCatalog.lumber.id] =
        (out[CommodityCatalog.lumber.id] ?? 0) + slots;
    out[CommodityCatalog.castIron.id] =
        (out[CommodityCatalog.castIron.id] ?? 0) + slots;
  }
  if (startingResources.initialWool > 0) {
    out[CommodityCatalog.wool.id] =
        (out[CommodityCatalog.wool.id] ?? 0) + startingResources.initialWool;
  }
  if (startingResources.initialPaper > 0) {
    out[CommodityCatalog.paper.id] =
        (out[CommodityCatalog.paper.id] ?? 0) + startingResources.initialPaper;
  }
  return out;
}

List<DiplomacyRelation> _buildInitialDiplomacyRelations({
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
}) {
  final allOldWorldIds = [...gpIds, ...minorIds];
  final allNewWorldIds = [...tribeIds];
  return <DiplomacyRelation>[
    for (var i = 0; i < allOldWorldIds.length; i++)
      for (var j = i + 1; j < allOldWorldIds.length; j++)
        DiplomacyRelation(
          factionId1: allOldWorldIds[i],
          factionId2: allOldWorldIds[j],
          score: relationScoreNeutral,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
    for (var i = 0; i < allNewWorldIds.length; i++)
      for (var j = i + 1; j < allNewWorldIds.length; j++)
        DiplomacyRelation(
          factionId1: allNewWorldIds[i],
          factionId2: allNewWorldIds[j],
          score: relationScoreNeutral,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
  ];
}
