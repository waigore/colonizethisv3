// Fixtures for appendMilitaryRegimentToArmy armiesById scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const amrPlayerId = 'p1';
const amrCapProvinceId = 'oldWorld|P1';

Player amrBuildPlayer() => Player(
  id: amrPlayerId,
  displayName: 'P1',
  isHuman: true,
  capitalProvinceId: amrCapProvinceId,
  stockpile: const Stockpile(),
  workerPool: const WorkerPool(peasants: 10),
  treasury: 10000,
);

Game amrEmptyArmyGame() {
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: amrCapProvinceId,
          regionId: 'oldWorld',
          ownerId: amrPlayerId,
        ),
      ],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  return Game(id: 'g', worldState: world, players: [amrBuildPlayer()]);
}

Game amrGameWithExistingHomeArmy() {
  final existing = Army(
    id: homeArmyIdFor(amrPlayerId),
    ownerId: amrPlayerId,
    regionId: 'oldWorld',
    stationedProvinceId: amrCapProvinceId,
    regimentUnitIds: const ['u_existing'],
    isHomeArmy: true,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: amrCapProvinceId,
          regionId: 'oldWorld',
          ownerId: amrPlayerId,
        ),
      ],
      units: [],
    ),
    newWorld: const RegionData(),
    armies: [existing],
  );
  return Game(id: 'g', worldState: world, players: [amrBuildPlayer()]);
}
