// Shared fixtures for order suggestion helper scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';

const orderSuggestionHelpersOw = 'oldWorld';
const orderSuggestionHelpersGpId = 'gp1';
const orderSuggestionHelpersMinorId = 'minor_doc';

Game orderSuggestionHelpersGameWithMinorProvince({
  required List<DiplomacyRelation> diplomacyRelations,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          const Province(
            id: '$orderSuggestionHelpersOw|P_gp',
            regionId: orderSuggestionHelpersOw,
            ownerId: orderSuggestionHelpersGpId,
          ),
          const Province(
            id: '$orderSuggestionHelpersOw|P_minor',
            regionId: orderSuggestionHelpersOw,
            ownerId: orderSuggestionHelpersMinorId,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: orderSuggestionHelpersGpId, displayName: 'GP1', isHuman: true),
    ],
    minorNations: const [
      MinorNation(id: orderSuggestionHelpersMinorId, displayName: 'Minor Doc'),
    ],
    diplomacyRelations: diplomacyRelations,
  );
}
