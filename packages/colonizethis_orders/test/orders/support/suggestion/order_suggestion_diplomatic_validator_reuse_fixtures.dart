// Diplomatic validator-reuse scenario fixtures (Refs #2394, #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const _emptyTopology = MapTopology(nodes: [], edges: []);

/// Two GPs at peace: each target's non-economic pass accepts [alliance]; the
/// economic pass must rebind via [forBasePrefix], not rebuild validators.
Game dvrTwoGpPeaceGame() {
  return Game(
    id: 'g_diplomatic_validator_reuse',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
  );
}

Game dvrThreeGpPeaceGame() {
  return Game(
    id: 'g_diplomatic_rebind',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      Player(id: 'gp3', displayName: 'GP3', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp3',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
  );
}

MapTopology get dvrEmptyTopology => _emptyTopology;
