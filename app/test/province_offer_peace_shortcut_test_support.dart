// Shared MAP20001 Offer Peace fixtures (Refs #4606 Slice D).
// SPEC/ui/province-sea-zone-detail-overlay.md — Political standing / Offer Peace.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const offerPeaceGameId = 'g_offer_peace_shortcut';
const offerPeaceHumanPlayerId = 'gp1';
const offerPeaceRivalId = 'gp2';
const offerPeaceProvinceId = 'oldWorld|p_rival';
const offerPeaceTileKey = 'oldWorld|p_rival|0|0';

final MapTopology offerPeaceTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|p_rival',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p_human',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game offerPeaceBuildGame({
  required String ownerId,
  RelationState relationState = RelationState.atPeace,
  bool formalAlliance = false,
  bool includeRelation = true,
}) {
  return Game(
    id: offerPeaceGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: offerPeaceProvinceId,
            regionId: 'oldWorld',
            ownerId: ownerId,
            townTileKey: offerPeaceTileKey,
          ),
          const Province(
            id: 'oldWorld|p_human',
            regionId: 'oldWorld',
            ownerId: offerPeaceHumanPlayerId,
            townTileKey: 'oldWorld|p_human|0|0',
          ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: const [
      Player(
        id: offerPeaceHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p_human',
        treasury: 5000,
      ),
      Player(
        id: offerPeaceRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: offerPeaceProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
    diplomacyRelations: includeRelation
        ? [
            DiplomacyRelation(
              factionId1: offerPeaceHumanPlayerId,
              factionId2: offerPeaceRivalId,
              state: relationState,
              formalAlliance: formalAlliance,
              score: formalAlliance ? 90 : 50,
            ),
          ]
        : const [],
  );
}
