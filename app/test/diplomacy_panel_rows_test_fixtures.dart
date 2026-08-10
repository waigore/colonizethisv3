import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Old World coastal province sea-connected to an unrevealed New World tribe
/// colony, with **zero** New World tile visibility (Refs #3620 AC-1). Mirrors
/// the colonial-intel fixture used in the diplomacy package tests.
const diplomacyPanelRowsSeaReachableTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|owSea',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSea',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|colony',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
    TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
    TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
  ],
);

Game diplomacyPanelRowsTribeFixture({
  required String id,
  required int turnNumber,
  required Map<String, Map<String, String>> playerVisibilityByTile,
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(id: 'newWorld|colony', regionId: 'newWorld', ownerId: 't1'),
        ],
      ),
      playerVisibilityByTile: playerVisibilityByTile,
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|home': ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': ['newWorld|colony|0|0'],
        },
      },
    ),
    players: const [Player(id: 'gp1', displayName: 'Solo', isHuman: true)],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
    diplomacyRelations: diplomacyRelations,
  );
}

/// Turn-0 fixture where Tribe `t1` owns a New-World province that is
/// sea-reachable from the human GP's Old-World anchor, but the GP has **no**
/// non-`unknown` New-World tile visibility and **no** GP↔Tribe relation
/// (Refs #3620 AC-1). The tribe must not be surfaced in the Tribes section.
Game diplomacyPanelRowsSeaReachableTribeNoContact() =>
    diplomacyPanelRowsTribeFixture(
      id: 'sea-reachable-no-contact',
      turnNumber: 0,
      playerVisibilityByTile: const {
        'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
      },
    );

/// Fixture for the contact-survives-fog-decay AC (Refs #3620 AC-7): the human
/// GP holds a persisted GP↔Tribe relation with `t1` but currently has **no**
/// non-`unknown` tile visibility into any province `t1` owns.
Game diplomacyPanelRowsTribeRelationButNoVisibility() =>
    diplomacyPanelRowsTribeFixture(
      id: 'tribe-relation-fog-decay',
      turnNumber: 7,
      playerVisibilityByTile: const {},
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 't1',
          state: RelationState.atPeace,
          score: 50,
          sinceTurn: 4,
          lastInteractionTurn: 4,
        ),
      ],
    );
