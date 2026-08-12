// Shared Game fixtures for planning_diplomatic_scans pins (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

const String kPlanningDiplomaticScansGp1 = 'gp1';
const String kPlanningDiplomaticScansGp2 = 'gp2';

Game planningDiplomaticScansGameWithEvents(List<DiplomaticEvent> events) {
  return Game(
    id: 'g-3717-cooldown-scan',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: kPlanningDiplomaticScansGp1, displayName: 'GP1', isHuman: false),
      Player(id: kPlanningDiplomaticScansGp2, displayName: 'GP2', isHuman: false),
    ],
    diplomaticHistoryEvents: events,
  );
}
