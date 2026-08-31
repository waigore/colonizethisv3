// Game fixtures for diplomacy panel mockup-fidelity tests (Refs #3621, #4305).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// Solo human Great Power with no other discovered factions, so every section
/// heading and the mode bar render against an otherwise empty list.
Game diplomacyMockupEmptyStateGame() {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'diplo-fidelity-empty',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

Game diplomacyMockupGpRelationGame(int score) {
  const ow = 'oldWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final rival = Province(
    id: '$ow|p2',
    regionId: ow,
    displayName: 'Rival',
    ownerId: 'gp2',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-fidelity-relation-$score',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: score),
    ],
  );
}

/// Human GP `gp1` pays an ongoing subsidy to GP `gp2`, so the `gp2` row
/// renders the outgoing-subsidy economic line.
Game _subsidyGame() {
  const ow = 'oldWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final rival = Province(
    id: '$ow|p2',
    regionId: ow,
    displayName: 'Rival',
    ownerId: 'gp2',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-fidelity-subsidy',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
    ],
    subsidyStates: const [
      SubsidyState(payerId: 'gp1', targetId: 'gp2', percent: 15),
    ],
  );
}

