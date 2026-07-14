// Shared feedstock-bootstrap castIron/lumber waiver fixtures (Refs #3971).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/feedstock_gate_graphs.dart';

const feedstockBootstrapSupplierId = ordersFeedstockGateSupplierId;
const feedstockBootstrapSellerId = ordersFeedstockGateSellerId;
const feedstockBootstrapGrainTile = ordersFeedstockGateGrainTile;
const feedstockBootstrapTimberTile = ordersFeedstockGateTimberTile;
const feedstockBootstrapIronTile = ordersFeedstockGateIronTile;
const feedstockBootstrapSellerWoolTile = ordersFeedstockGateSellerWoolTile;

Game twoPlayerFeedstockGateGame({
  required Stockpile supplierStockpile,
  Stockpile sellerStockpile = const Stockpile(quantities: {'lumber': 1}),
}) => ordersFeedstockGateGame(
  players: ordersFeedstockGateDefaultPlayers(
    supplierStockpile: supplierStockpile,
    sellerStockpile: sellerStockpile,
  ),
);
