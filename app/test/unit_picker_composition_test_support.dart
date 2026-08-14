// Shared fixtures for DLG20002 / DLG31003 composition tests (Refs #4385).

import 'package:colonizethis_models/colonizethis_models.dart';

const unitPickerTestPlayerId = 'gp_picker';
const unitPickerTestProvince = 'oldWorld|p1';

Game unitPickerArmyGame({
  required List<Army> armies,
  required List<Unit> units,
}) {
  return Game(
    id: 'g_picker_army',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: unitPickerTestProvince,
            regionId: 'oldWorld',
            ownerId: unitPickerTestPlayerId,
            displayName: 'P1',
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: const [
      Player(id: unitPickerTestPlayerId, displayName: 'Human', isHuman: true),
    ],
  );
}

Game unitPickerFleetGame(List<Fleet> fleets) {
  return Game(
    id: 'g_picker_fleet',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: const [
      Player(id: unitPickerTestPlayerId, displayName: 'Human', isHuman: true),
    ],
  );
}
