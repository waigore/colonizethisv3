// Shared fixtures for treasury-budget pin cases (Refs #3997 Phase 8).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

const String kTreasuryBudgetGpId = 'gp1';

Game treasuryBudgetTestGameFor({
  required int treasury,
  Stockpile stockpile = const Stockpile(),
  Map<CommodityId, int>? prices,
  Map<String, List<TradeOrder>>? carryForwardBidsByFactionId,
  Map<String, MarketActivity>? lastTurnActivity,
  int turnNumber = 1,
  List<OvertureState> overtures = const [],
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g_treasury_cap',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: kTreasuryBudgetGpId),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: kTreasuryBudgetGpId,
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    overtureStates: overtures,
    worldMarketState: WorldMarketState.withDefaultPrices(
      prices ??
          const {
            'timber': 20,
            'iron': 20,
            'fabric': 40,
            'castIron': 60,
          },
    ).copyWith(
      carryForwardBidsByFactionId: carryForwardBidsByFactionId,
      lastTurnActivity: lastTurnActivity,
    ),
  );
}

List<TradeOrder> treasuryBudgetTestBids(List<TradeOrder> orders) =>
    orders.where((o) => o.type == TradeOrderType.bid).toList();

const kTreasuryBudgetEmbassyOverture = OvertureState(
  gpId: kTreasuryBudgetGpId,
  targetId: 'minor1',
  stage: OvertureStage.embassy,
  sinceTurn: 0,
);
