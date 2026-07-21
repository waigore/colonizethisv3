// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
Game tradeInterceptionGame({String id = 'g1', List<Fleet> fleets = const [], List<DiplomacyRelation> diplomacyRelations = const [], List<Player>? players, RelationState defaultRelation = RelationState.atPeace}) {
  final resolvedPlayers = players ?? const [Player(id: 'p1', displayName: 'A', isHuman: true), Player(id: 'p2', displayName: 'B', isHuman: true)];
  final resolvedRelations = diplomacyRelations.isNotEmpty ? diplomacyRelations : [DiplomacyRelation(factionId1: 'p1', factionId2: 'p2', state: defaultRelation)];
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: resolvedPlayers,
    diplomacyRelations: resolvedRelations,
  );
}
Game tradeInterceptionPrivateeringGame({required bool enemyHasPrivateering, String gameId = 'g1'}) {
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(id: 'enemy', ownerId: 'p2', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['sloop'], mission: FleetMission.patrol),
        Fleet(id: 'mine', ownerId: 'p1', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['fluyte']),
      ],
    ),
    players: [
      const Player(id: 'p1', displayName: 'A', isHuman: true),
      Player(id: 'p2', displayName: 'B', isHuman: false, techUnlocked: enemyHasPrivateering ? const {kTechIdPrivateeringCompanies: true} : const {}),
    ],
    diplomacyRelations: const [DiplomacyRelation(factionId1: 'p1', factionId2: 'p2', state: RelationState.atWar)],
  );
}
Game minimalTwoPlayerGame({String id = 'g1', int turnNumber = 0, List<Player>? players}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players ?? const [Player(id: 'p1', displayName: 'A', isHuman: true), Player(id: 'p2', displayName: 'B', isHuman: false)],
  );
}
Game minimalGpGame({String id = 'g1', String playerId = 'gp1', int turnNumber = 1}) {
  return Game(
    id: id,
    players: [Player(id: playerId, displayName: playerId, isHuman: false, stockpile: Stockpile.empty, treasury: 0)],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
  );
}
Game buildTreasuryBidBudgetGame({int treasury = 100, Map<CommodityId, int>? prices, Map<CommodityId, int>? stockpile, WorldMarketState? worldMarketState, String playerId = 'gp_h', String gameId = 'test_treasury_bid_budget', String playerDisplayName = 'England', bool isHuman = true, List<TradeOrder>? carryForwardBids}) {
  final resolvedPrices = prices ?? const <CommodityId, int>{};
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: isHuman,
        treasury: treasury,
        stockpile: Stockpile(quantities: stockpile ?? const <CommodityId, int>{}),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: worldMarketState ?? WorldMarketState(prices: resolvedPrices, carryForwardBidsByFactionId: carryForwardBids == null ? const {} : {playerId: carryForwardBids}),
  );
}
Game gameForNonGpExtractionTest({required List<Province> provinces, TileMapState? tileState, List<MinorNation> minorNations = const [], List<Tribe> tribes = const [], int capitalTileGrainBonusPerTurn = 0, List<Province> newWorldProvinces = const [], String id = 'g_test', List<Player> players = const [], Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {}}) {
  return Game(
    id: id,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: provinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileState: tileState ?? TileMapState(),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}
Game gameWithColonyTribeBoycottTest({List<ColonyState> colonyStates = const [], List<BoycottState> boycottStates = const []}) {
  final tileState = TileMapState().setImprovement('newWorld|t1|0|0', 1).setRoadLevel('newWorld|t1|0|0', 1);
  return Game(
    id: 'g_boycott_test',
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [Province(id: 'newWorld|t1', regionId: 'newWorld', ownerId: 't1', townDevelopmentLevel: 1)],
      ),
      tileState: tileState,
    ),
    players: const [
      Player(id: 'gpA', displayName: 'Aragon', isHuman: false),
      Player(id: 'gpC', displayName: 'Castile', isHuman: false),
    ],
    tribes: [Tribe(id: 't1', capitalProvinceId: 'newWorld|t1', capitalTile: CapitalTile(regionId: 'newWorld', provinceId: 'newWorld|t1', x: 0, y: 0))],
    colonyStates: colonyStates,
    boycottStates: boycottStates,
  );
}
// dart format on
