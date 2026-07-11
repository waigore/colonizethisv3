// Shared fixtures for order suggestion helper scenarios
// (Refs #3949 wave 3 / #3971 wave 4).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const orderSuggestionHelpersOw = 'oldWorld';
const orderSuggestionHelpersGpId = 'gp1';
const orderSuggestionHelpersMinorId = 'minor_doc';

Game orderSuggestionHelpersGameWithMinorProvince({
  required List<DiplomacyRelation> diplomacyRelations,
}) => ordersOwRegionGame(
  turnNumber: 1,
  players: const [
    Player(id: orderSuggestionHelpersGpId, displayName: 'GP1', isHuman: true),
  ],
  oldWorld: const RegionData(
    provinces: [
      Province(
        id: '$orderSuggestionHelpersOw|P_gp',
        regionId: orderSuggestionHelpersOw,
        ownerId: orderSuggestionHelpersGpId,
      ),
      Province(
        id: '$orderSuggestionHelpersOw|P_minor',
        regionId: orderSuggestionHelpersOw,
        ownerId: orderSuggestionHelpersMinorId,
      ),
    ],
  ),
  minorNations: const [
    MinorNation(id: orderSuggestionHelpersMinorId, displayName: 'Minor Doc'),
  ],
  diplomacyRelations: diplomacyRelations,
);
