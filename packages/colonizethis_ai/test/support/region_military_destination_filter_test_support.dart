// Shared Game fixtures for region_military_destination_filter pins
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game regionMilitaryDestinationFilterGame({
  required List<Province> oldWorld,
  required List<Province> newWorld,
}) {
  return Game(
    id: 'region-military-dest-filter',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorld),
      newWorld: RegionData(provinces: newWorld),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
  );
}
