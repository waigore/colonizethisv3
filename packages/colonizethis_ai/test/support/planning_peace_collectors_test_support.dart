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

/// Three minors (A/B/C) plus tribe1 for minor-at-war collector pins.
Game planningPeaceCollectorsGameWithMinors() {
  return Game(
    id: 'g-3717-minor-peace',
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
    ],
    minorNations: const [
      MinorNation(id: 'minorA', displayName: 'MinorA'),
      MinorNation(id: 'minorB', displayName: 'MinorB'),
      MinorNation(id: 'minorC', displayName: 'MinorC'),
    ],
    tribes: const [
      Tribe(id: planningPeaceCollectorsTribe1, displayName: 'Tribe1'),
    ],
  );
}

/// Three tribes (A/B/C) plus minorA for tribe-at-war collector pins.
Game planningPeaceCollectorsGameWithTribes() {
  return Game(
    id: 'g-3717-tribe-peace',
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
    ],
    minorNations: const [MinorNation(id: 'minorA', displayName: 'MinorA')],
    tribes: const [
      Tribe(id: 'tribeA', displayName: 'TribeA'),
      Tribe(id: 'tribeB', displayName: 'TribeB'),
      Tribe(id: 'tribeC', displayName: 'TribeC'),
    ],
  );
}

/// Two GPs, two minors, and tribe1 for non-GP at-war collector pins.
Game planningPeaceCollectorsGameWithMixedFactions() {
  return Game(
    id: 'g-3749-non-gp-peace',
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
    ],
    minorNations: const [
      MinorNation(id: 'minorA', displayName: 'MinorA'),
      MinorNation(id: 'minorB', displayName: 'MinorB'),
    ],
    tribes: const [
      Tribe(id: planningPeaceCollectorsTribe1, displayName: 'Tribe1'),
    ],
  );
}
