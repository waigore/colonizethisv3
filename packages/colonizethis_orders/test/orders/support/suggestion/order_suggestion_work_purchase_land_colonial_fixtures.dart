// Embassy-stage NW purchase_land colonial fixtures (Refs #2509, #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';

const purchaseLandColonialGpId = 'gp1';
const purchaseLandColonialTribeId = 'tribe1';
const purchaseLandColonialMerchantId = 'm1';
const purchaseLandColonialHomeProvinceId = 'oldWorld|home';
const purchaseLandColonialColonyProvinceId = 'newWorld|colony';
const purchaseLandColonialHomeTileKey = 'oldWorld|home|0|0';
const purchaseLandColonialColonyTileKey = 'newWorld|colony|0|0';

/// Embassy-stage NW colonial scenario for Merchant `purchase_land` pins.
Game purchaseLandColonialScenarioGame({bool withEmbassy = true}) {
  return Game(
    id: 'g-2509-purchase-land-colonial',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: purchaseLandColonialHomeProvinceId,
            regionId: 'oldWorld',
            ownerId: purchaseLandColonialGpId,
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: purchaseLandColonialColonyProvinceId,
            regionId: 'newWorld',
            ownerId: purchaseLandColonialTribeId,
          ),
        ],
        units: [
          Unit(
            id: purchaseLandColonialMerchantId,
            type: kUnitTypeMerchant,
            ownerId: purchaseLandColonialGpId,
            locationProvinceId: purchaseLandColonialColonyProvinceId,
            tileKey: purchaseLandColonialColonyTileKey,
          ),
        ],
      ),
      playerVisibilityByTile: const {
        purchaseLandColonialGpId: {
          purchaseLandColonialHomeTileKey: 'fullyVisible',
          purchaseLandColonialColonyTileKey: 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          purchaseLandColonialHomeProvinceId: [purchaseLandColonialHomeTileKey],
        },
        'newWorld': {
          purchaseLandColonialColonyProvinceId: [
            purchaseLandColonialColonyTileKey,
          ],
        },
      },
      resourceByTileKey: const {purchaseLandColonialColonyTileKey: 'grain'},
    ),
    players: const [
      Player(
        id: purchaseLandColonialGpId,
        displayName: 'GP1',
        isHuman: false,
        treasury: 1000,
        techUnlocked: {kTechIdMerchantCompanies: true},
      ),
    ],
    tribes: const [Tribe(id: purchaseLandColonialTribeId, displayName: 'T1')],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: purchaseLandColonialGpId,
        factionId2: purchaseLandColonialTribeId,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
    overtureStates: withEmbassy
        ? const [
            OvertureState(
              gpId: purchaseLandColonialGpId,
              targetId: purchaseLandColonialTribeId,
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ]
        : const <OvertureState>[],
  );
}

PlayerView purchaseLandColonialViewFor(Game game) => buildPlayerView(
  game,
  colonialAcquisitionTopology,
  purchaseLandColonialGpId,
);

String purchaseLandColonialWorkOrderKey(WorkOrder o) =>
    '${o.unitId}:${o.target}:${o.targetTileKey}';
