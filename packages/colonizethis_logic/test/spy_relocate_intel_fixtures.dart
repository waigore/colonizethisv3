import 'package:colonizethis_models/colonizethis_models.dart';

const kSpyRelocateHumanId = 'h1';
const kSpyRelocateRivalId = 'gp2';

Game spyRelocateTwoProvinceGame() {
  return Game(
    id: 'g1',
    players: const [
      Player(id: kSpyRelocateHumanId, displayName: 'Human', isHuman: true),
      Player(id: kSpyRelocateRivalId, displayName: 'Rival', isHuman: false),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Home',
            ownerId: kSpyRelocateHumanId,
          ),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            displayName: 'Rival Land',
            ownerId: kSpyRelocateRivalId,
          ),
        ],
        units: [
          Unit(
            id: 'spy1',
            type: kUnitTypeSpy,
            ownerId: kSpyRelocateHumanId,
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
  );
}

Game spyRelocateDualSpyForeignGame() {
  return Game(
    id: 'g1',
    players: const [
      Player(id: kSpyRelocateHumanId, displayName: 'Human', isHuman: true),
      Player(id: kSpyRelocateRivalId, displayName: 'Rival', isHuman: false),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Home',
            ownerId: kSpyRelocateHumanId,
          ),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            displayName: 'Rival Land',
            ownerId: kSpyRelocateRivalId,
          ),
        ],
        units: [
          Unit(
            id: 'spy1',
            type: kUnitTypeSpy,
            ownerId: kSpyRelocateHumanId,
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|0|0',
          ),
          Unit(
            id: 'spy2',
            type: kUnitTypeSpy,
            ownerId: kSpyRelocateHumanId,
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|1|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
  );
}

Game spyRelocateOwnedProvinceSpyGame() {
  return Game(
    id: 'g1',
    players: const [
      Player(id: kSpyRelocateHumanId, displayName: 'Human', isHuman: true),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Home',
            ownerId: kSpyRelocateHumanId,
          ),
        ],
        units: [
          Unit(
            id: 'spy1',
            type: kUnitTypeSpy,
            ownerId: kSpyRelocateHumanId,
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
  );
}
