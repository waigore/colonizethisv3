// Shared Upgrade town payoff fixtures (Refs #4747).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

const upgradeTownPayoffHumanId = 'gp1';
const upgradeTownPayoffProvinceId = 'oldWorld|p1';
const upgradeTownPayoffTile = 'oldWorld|p1|0|0';
const upgradeTownPayoffBuilderId = 'u_builder';

Game upgradeTownPayoffPanelGame({required String id, int townLevel = 2}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: upgradeTownPayoffProvinceId,
            regionId: 'oldWorld',
            ownerId: upgradeTownPayoffHumanId,
            displayName: 'Alpha',
            townDevelopmentLevel: townLevel,
            townTileKey: upgradeTownPayoffTile,
          ),
        ],
        units: [
          Unit(
            id: upgradeTownPayoffBuilderId,
            type: kUnitTypeBuilder,
            ownerId: upgradeTownPayoffHumanId,
            locationProvinceId: upgradeTownPayoffProvinceId,
            tileKey: upgradeTownPayoffTile,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          upgradeTownPayoffProvinceId: [upgradeTownPayoffTile],
        },
      },
    ),
    players: const [
      Player(id: upgradeTownPayoffHumanId, displayName: 'Human', isHuman: true),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

Orders upgradeTownPayoffPendingOrders() {
  return const Orders(
    workOrdersByPlayerId: {
      upgradeTownPayoffHumanId: [
        WorkOrder(
          unitId: upgradeTownPayoffBuilderId,
          target: kWorkTargetUpgradeTown,
          targetTileKey: upgradeTownPayoffTile,
        ),
      ],
    },
  );
}
