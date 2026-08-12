// Shared Game fixtures for DEVELOP NW purchase-suppression orchestrator pin
// (Refs #4310 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kDevelopNwPurchaseSuppressionNationId = 'gp1';
const String kDevelopNwPurchaseSuppressionOwProvince = 'oldWorld|home';
const String kDevelopNwPurchaseSuppressionNwOwnedProvince = 'newWorld|owned';
const String kDevelopNwPurchaseSuppressionNwTribeProvince = 'newWorld|tribe';
const String kDevelopNwPurchaseSuppressionOwTile =
    '$kDevelopNwPurchaseSuppressionOwProvince|0|0';
const String kDevelopNwPurchaseSuppressionNwOwnedTile =
    '$kDevelopNwPurchaseSuppressionNwOwnedProvince|0|0';
const String kDevelopNwPurchaseSuppressionNwTribeTile =
    '$kDevelopNwPurchaseSuppressionNwTribeProvince|0|0';

/// Game with one OW Builder, one NW Builder (in a GP-owned NW province), and
/// one NW Merchant (in a tribe-owned NW province).
Game developNwPurchaseSuppressionScenarioGame() {
  return Game(
    id: 'g-2509-develop-nw-purchase-suppress',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 140),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kDevelopNwPurchaseSuppressionOwProvince,
            regionId: 'oldWorld',
            ownerId: kDevelopNwPurchaseSuppressionNationId,
          ),
        ],
        units: [
          Unit(
            id: 'b_ow',
            type: kUnitTypeBuilder,
            ownerId: kDevelopNwPurchaseSuppressionNationId,
            locationProvinceId: kDevelopNwPurchaseSuppressionOwProvince,
            tileKey: kDevelopNwPurchaseSuppressionOwTile,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: kDevelopNwPurchaseSuppressionNwOwnedProvince,
            regionId: 'newWorld',
            ownerId: kDevelopNwPurchaseSuppressionNationId,
          ),
          Province(
            id: kDevelopNwPurchaseSuppressionNwTribeProvince,
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
        units: [
          Unit(
            id: 'b_nw',
            type: kUnitTypeBuilder,
            ownerId: kDevelopNwPurchaseSuppressionNationId,
            locationProvinceId: kDevelopNwPurchaseSuppressionNwOwnedProvince,
            tileKey: kDevelopNwPurchaseSuppressionNwOwnedTile,
          ),
          Unit(
            id: 'm_nw',
            type: kUnitTypeMerchant,
            ownerId: kDevelopNwPurchaseSuppressionNationId,
            locationProvinceId: kDevelopNwPurchaseSuppressionNwTribeProvince,
            tileKey: kDevelopNwPurchaseSuppressionNwTribeTile,
          ),
        ],
      ),
      playerVisibilityByTile: const {
        kDevelopNwPurchaseSuppressionNationId: {
          kDevelopNwPurchaseSuppressionOwTile: 'fullyVisible',
          kDevelopNwPurchaseSuppressionNwOwnedTile: 'fullyVisible',
          kDevelopNwPurchaseSuppressionNwTribeTile: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kDevelopNwPurchaseSuppressionOwProvince: [
            kDevelopNwPurchaseSuppressionOwTile,
          ],
        },
        'newWorld': {
          kDevelopNwPurchaseSuppressionNwOwnedProvince: [
            kDevelopNwPurchaseSuppressionNwOwnedTile,
          ],
          kDevelopNwPurchaseSuppressionNwTribeProvince: [
            kDevelopNwPurchaseSuppressionNwTribeTile,
          ],
        },
      },
      resourceByTileKey: const {
        kDevelopNwPurchaseSuppressionOwTile: 'grain',
        kDevelopNwPurchaseSuppressionNwOwnedTile: 'grain',
        kDevelopNwPurchaseSuppressionNwTribeTile: 'grain',
      },
    ),
    players: const [
      Player(
        id: kDevelopNwPurchaseSuppressionNationId,
        displayName: 'GP',
        isHuman: false,
        leaderKey: 'victoria',
      ),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
  );
}
