import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared [Orders] fixtures for models package tests (Refs #4136 Slice D).
const sampleMoveOrder = MoveOrder(
  unitId: 'u1',
  destinationTileKey: 'oldWorld|prov1|0|0',
);

const sampleBuildUnitOrder = BuildUnitOrder(
  unitType: 'Regiment',
  isMilitary: true,
  spawnProvinceId: 'oldWorld|prov1',
);

const sampleWorkOrder = WorkOrder(
  unitId: 'u1',
  target: 'build_mine',
  targetTileKey: 'oldWorld|prov1|0|0',
);

const sampleOrdersWithBasics = Orders(
  moveOrdersByPlayerId: {
    'p1': [sampleMoveOrder],
  },
  buildUnitOrdersByPlayerId: {
    'p1': [sampleBuildUnitOrder],
  },
  workOrdersByPlayerId: {
    'p1': [sampleWorkOrder],
  },
);

const allWorkerTierRecruitOrders = Orders(
  recruitWorkerOrdersByPlayerId: {
    'p1': [
      RecruitWorkerOrder(targetTier: WorkerTier.peasant),
      RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
      RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
      RecruitWorkerOrder(targetTier: WorkerTier.master),
    ],
  },
);

Orders sampleTradeOrders({
  int player1OfferQuantity = 10,
  int player1BidQuantity = 3,
  String player2Commodity = 'silk',
}) =>
    Orders(
      tradeOrdersByPlayerId: {
        'p1': [
          TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.offer,
            quantity: player1OfferQuantity,
            priority: 1,
          ),
          TradeOrder(
            commodityId: 'iron',
            type: TradeOrderType.bid,
            quantity: player1BidQuantity,
            priority: 2,
          ),
        ],
        'p2': [
          TradeOrder(
            commodityId: player2Commodity,
            type: TradeOrderType.bid,
            quantity: 5,
            priority: 1,
            isFtp: true,
          ),
        ],
      },
    );
