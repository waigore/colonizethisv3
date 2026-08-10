// Shared Game / snapshot fixtures for planning peace-collector pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String planningPeaceCollectorsGp1 = 'gp1';
const String planningPeaceCollectorsGp2 = 'gp2';
const String planningPeaceCollectorsGp3 = 'gp3';
const String planningPeaceCollectorsTribe1 = 'tribe1';
const String planningPeaceCollectorsMinor1 = 'minor1';

Game planningPeaceCollectorsGameWithGps() {
  return Game(
    id: 'g-3278-planning-helpers',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(
        id: planningPeaceCollectorsGp1,
        displayName: 'GP1',
        isHuman: false,
      ),
      Player(
        id: planningPeaceCollectorsGp2,
        displayName: 'GP2',
        isHuman: false,
      ),
      Player(
        id: planningPeaceCollectorsGp3,
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: planningPeaceCollectorsMinor1,
        displayName: 'Minor1',
      ),
    ],
    tribes: const [
      Tribe(id: planningPeaceCollectorsTribe1, displayName: 'Tribe1'),
    ],
  );
}

AIWorldSnapshot planningPeaceCollectorsSnapshotWithAtWar(
  List<String> atWarWith,
) {
  return AIWorldSnapshot(
    playerId: planningPeaceCollectorsGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
