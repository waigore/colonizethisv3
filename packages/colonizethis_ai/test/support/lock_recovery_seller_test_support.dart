/// Shared lock-recovery seller Game scaffolds for cast-iron labour and
/// H8 feedstock orchestrator pins (Refs #2847 / #3997).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Seller id used by cast-iron labour gate pins.
const String kCastIronLabourLockRecoverySellerId = 'gp5';

/// Iron resource tile for cast-iron labour lock-recovery seller.
const String kCastIronLabourLockRecoveryIronTile = 'oldWorld|p0|2|0';

/// Seller id used by H8 feedstock civilian-work orchestrator pins.
const String kH8FeedstockLockRecoverySellerId = 'gp_seller';

/// Grain resource tile for H8 feedstock lock-recovery seller.
const String kH8FeedstockLockRecoveryGrainTile = 'oldWorld|p0|0|0';

/// Wool resource tile for H8 feedstock lock-recovery seller.
const String kH8FeedstockLockRecoveryWoolTile = 'oldWorld|p0|1|0';

/// Cast-iron labour gate seller: five OW provinces, iron tile, tunable
/// worker pool / stockpile (Refs #3997).
Game buildCastIronLabourLockRecoverySellerGame({
  required WorkerPool workerPool,
  required Stockpile stockpile,
}) {
  return Game(
    id: 'g-castiron-labour',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|p$i',
              regionId: kRegionOldWorld,
              ownerId: kCastIronLabourLockRecoverySellerId,
            ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {
        kCastIronLabourLockRecoveryIronTile: 'iron',
      },
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|p0': [kCastIronLabourLockRecoveryIronTile],
        },
      },
    ),
    players: [
      Player(
        id: kCastIronLabourLockRecoverySellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: stockpile,
        workerPool: workerPool,
      ),
    ],
  );
}

/// H8 feedstock orchestrator seller: five OW provinces, grain+wool tiles,
/// one idle Builder, tunable treasury (Refs #3997).
Game buildH8FeedstockLockRecoverySellerGame({required int treasury}) {
  return Game(
    id: 'g-h8-extraction-orchestrator',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|p$i',
              regionId: kRegionOldWorld,
              ownerId: kH8FeedstockLockRecoverySellerId,
            ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: kH8FeedstockLockRecoverySellerId,
            locationProvinceId: 'oldWorld|p0',
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {
        kH8FeedstockLockRecoveryGrainTile: 'grain',
        kH8FeedstockLockRecoveryWoolTile: 'wool',
      },
      playerVisibilityByTile: const {
        kH8FeedstockLockRecoverySellerId: {
          kH8FeedstockLockRecoveryGrainTile: 'fullyVisible',
          kH8FeedstockLockRecoveryWoolTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|p0': [
            kH8FeedstockLockRecoveryGrainTile,
            kH8FeedstockLockRecoveryWoolTile,
          ],
        },
      },
    ),
    players: [
      Player(
        id: kH8FeedstockLockRecoverySellerId,
        displayName: 'Seller',
        isHuman: false,
        leaderKey: 'napoleon',
        treasury: treasury,
      ),
    ],
  );
}
