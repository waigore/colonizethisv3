// Shared draft-order mutation fixtures (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';

final draftOrdersTimberBid = TradeOrder(
  commodityId: 'timber',
  type: TradeOrderType.bid,
  quantity: 5,
  priority: 1,
);

final draftOrdersTimberOffer = TradeOrder(
  commodityId: 'timber',
  type: TradeOrderType.offer,
  quantity: 3,
  priority: 1,
);

final draftOrdersFabricBid = TradeOrder(
  commodityId: 'fabric',
  type: TradeOrderType.bid,
  quantity: 2,
  priority: 1,
);

const draftOrdersWorkOrderW0 = WorkOrder(
  unitId: 'u0',
  target: kWorkTargetExplore,
  targetTileKey: 'oldWorld|p1|0|0',
);

const draftOrdersWorkOrderW1 = WorkOrder(
  unitId: 'u1',
  target: kWorkTargetExplore,
  targetTileKey: 'oldWorld|p2|0|0',
);
