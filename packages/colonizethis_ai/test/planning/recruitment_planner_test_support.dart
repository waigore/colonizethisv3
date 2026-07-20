// Shared Game factory for recruitment planner pins (Refs #4104 Slice A).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

Game recruitmentPlannerTestGameWith(Player player) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [], units: []),
    newWorld: RegionData(provinces: [], units: []),
  ),
  players: [player],
);
