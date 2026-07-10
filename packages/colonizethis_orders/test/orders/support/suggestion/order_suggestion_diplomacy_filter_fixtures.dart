// Shared diplomacy-filter suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Dual-region game with two GPs and one unowned old-world province.
Game orderSuggestionDiplomacyFilterDualRegionGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'oldWorld|p1', regionId: ow, ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: ow, ownerId: 'gp2'),
          Province(id: 'oldWorld|p3', regionId: ow),
        ],
        units: const [],
      ),
      newWorld: RegionData(
        provinces: const [
          Province(id: 'newWorld|n1', regionId: nw, ownerId: 'gp1'),
        ],
        units: const [],
      ),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
  );
}

/// Old-world game with empty-string owner on one province.
Game orderSuggestionDiplomacyFilterEmptyStringOwnerGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'oldWorld|p1', regionId: ow, ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: ow, ownerId: ''),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
  );
}

/// Two-GP old-world game with unprefixed local province ids.
Game orderSuggestionDiplomacyFilterOldWorldTwoGpGame() {
  const ow = 'oldWorld';
  final p1 = Province(id: 'p1', regionId: ow, ownerId: 'gp1');
  final p2 = Province(id: 'p2', regionId: ow, ownerId: 'gp2');
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [p1, p2], units: []),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
  );
}

/// Two-GP new-world game with prefixed province ids.
Game orderSuggestionDiplomacyFilterNewWorldTwoGpGame() {
  const nw = 'newWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|n1', regionId: nw, ownerId: 'gp1'),
          Province(id: 'newWorld|n2', regionId: nw, ownerId: 'gp2'),
        ],
        units: [],
      ),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
  );
}

/// Two-GP old-world game at peace for diplomacy filter probes.
Game orderSuggestionDiplomacyFilterPeacefulTwoGpGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
          Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 50,
        state: RelationState.atPeace,
      ),
    ],
  );
}

/// Two-GP old-world game at war for diplomacy filter probes.
Game orderSuggestionDiplomacyFilterAtWarTwoGpGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
          Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 0,
        state: RelationState.atWar,
      ),
    ],
  );
}
