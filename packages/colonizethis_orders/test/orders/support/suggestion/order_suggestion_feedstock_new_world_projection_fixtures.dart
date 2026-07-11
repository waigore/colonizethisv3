// Feedstock new-world projection fixtures (Refs #3971).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/feedstock_gate_graphs.dart';

const feedstockNwProjectionSupplierId = ordersFeedstockGateSupplierId;
const feedstockNwProjectionSellerId = ordersFeedstockGateSellerId;
const feedstockNwProjectionGrainTile = ordersFeedstockGateGrainTile;
const feedstockNwProjectionTimberTile = ordersFeedstockGateTimberTile;
const feedstockNwProjectionIronTile = ordersFeedstockGateIronTile;
const feedstockNwProjectionSellerWoolTile = ordersFeedstockGateSellerWoolTile;

Game feedstockNwProjectionGame({int sellerNw = 0}) => ordersFeedstockGateGame(
  sellerNw: sellerNw,
  players: ordersFeedstockGateDefaultPlayers(
    supplierStockpile: const Stockpile(quantities: {'lumber': 10}),
  ),
);
