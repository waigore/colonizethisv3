// Shared fixtures for diplomatic standing chip tests (Refs #3753 / #4720).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds a game where the human GP `gp1` holds an Embassy-stage overture with
/// Tribe `t1`, `t1` is a colony of `gp1`, and `gp1` boycotts GP `gp2` (Castile)
/// through that colony.
Game diplomacyStandingColonyTribeGame() {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final tribeProvince = Province(
    id: '$nw|t1prov',
    regionId: nw,
    displayName: 'Tribe Land',
    ownerId: 't1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
    oldWorld: RegionData(provinces: [home], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'standing-colony',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 't1', score: 60),
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 40),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gp1', targetId: 't1', stage: OvertureStage.embassy),
    ],
    colonyStates: const [
      ColonyState(tribeId: 't1', colonyOfGpId: 'gp1', sinceTurn: 5),
    ],
    boycottStates: const [
      BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 6),
    ],
  );
}

/// Foreign colony boycotting the human GP (Refs #3753 R12).
Game diplomacyStandingBoycottedByGame() {
  const nw = 'newWorld';
  return Game(
    id: 'standing-boycotted-by',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$nw|t2prov',
            regionId: nw,
            displayName: 'Foreign Colony Land',
            ownerId: 't2',
          ),
        ],
      ),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    tribes: const [Tribe(id: 't2', displayName: 'Aztec')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 't2', score: 45),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 't2',
        stage: OvertureStage.tradeConsulate,
      ),
    ],
    colonyStates: const [
      ColonyState(tribeId: 't2', colonyOfGpId: 'gp2', sinceTurn: 7),
    ],
    boycottStates: const [
      BoycottState(gpId: 'gp2', targetGpId: 'gp1', sinceTurn: 8),
    ],
  );
}

Game diplomacyStandingMinorJoinEmpireGame() {
  return Game(
    id: 'standing-minor-je',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
  );
}

Game diplomacyStandingOverseasGame() {
  return Game(
    id: 'standing-overseas',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
  );
}

Game diplomacyStandingEmptyGame() {
  return Game(
    id: 'standing-empty',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
  );
}
