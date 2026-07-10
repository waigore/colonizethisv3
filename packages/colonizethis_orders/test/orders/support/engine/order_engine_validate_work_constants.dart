// Shared validateWork constants and stockpile helpers (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

abstract final class ValidateWorkOw {
  static const ow = 'oldWorld';
  static const provinceId = '$ow|P1';
  static const tileKey = '$provinceId|0|0';

  static MapTopology topology() => const MapTopology(
    nodes: [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: [],
  );
}

Stockpile lumberCastIronStockpile(int amount) => Stockpile()
    .applyDelta(CommodityCatalog.lumber.id, amount)
    .applyDelta(CommodityCatalog.castIron.id, amount);

/// Embassy overture with minor1 for purchase-land validateWork scenarios.
const purchaseLandEmbassyOverture = [
  OvertureState(
    gpId: 'p1',
    targetId: 'minor1',
    stage: OvertureStage.embassy,
    sinceTurn: 0,
  ),
];

/// Embassy overture for gp1 minor-province road validateWork scenarios.
const minorProvinceEmbassyOverture = [
  OvertureState(
    gpId: 'gp1',
    targetId: 'minor1',
    stage: OvertureStage.embassy,
    sinceTurn: 0,
  ),
];

String minorProvinceRoadTileKey() => '${ValidateWorkOw.ow}|MN|0|0';
