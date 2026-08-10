// Shared Game / snapshot fixtures for planning invadable-owner pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String planningInvadableOwnersGp1 = 'gp1';
const String planningInvadableOwnersGp2 = 'gp2';
const String planningInvadableOwnersGp3 = 'gp3';
const String planningInvadableOwnersTribe1 = 'tribe1';
const String planningInvadableOwnersMinor1 = 'minor1';

Game planningInvadableOwnersGameWithGps() {
  return Game(
    id: 'g-3717-planning-helpers-invadable',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(
        id: planningInvadableOwnersGp1,
        displayName: 'GP1',
        isHuman: false,
      ),
      Player(
        id: planningInvadableOwnersGp2,
        displayName: 'GP2',
        isHuman: false,
      ),
      Player(
        id: planningInvadableOwnersGp3,
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: planningInvadableOwnersMinor1,
        displayName: 'Minor1',
      ),
    ],
    tribes: const [
      Tribe(id: planningInvadableOwnersTribe1, displayName: 'Tribe1'),
    ],
  );
}

Game planningInvadableOwnersGameWithTwoMinors() {
  const minor2 = 'minor2';
  return Game(
    id: 'g-3717-minor-collector',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(
        id: planningInvadableOwnersGp1,
        displayName: 'GP1',
        isHuman: false,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: planningInvadableOwnersMinor1,
        displayName: 'Minor1',
      ),
      MinorNation(id: minor2, displayName: 'Minor2'),
    ],
    tribes: const [
      Tribe(id: planningInvadableOwnersTribe1, displayName: 'Tribe1'),
    ],
  );
}

AIWorldSnapshot planningInvadableOwnersSnapshotWithInvadable(
  List<String> invadableProvinceIds,
) {
  return AIWorldSnapshot(
    playerId: planningInvadableOwnersGp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(invadableProvinceIdsSorted: invadableProvinceIds),
    economy: const EconomySummary(),
    relations: const {},
  );
}

AIWorldSnapshot planningInvadableOwnersCollectorSnapshot(
  List<String> invadable,
  List<String> atWarWith,
) {
  return AIWorldSnapshot(
    playerId: planningInvadableOwnersGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(invadableProvinceIdsSorted: invadable),
    economy: const EconomySummary(),
    relations: const {},
  );
}

AIWorldSnapshot planningInvadableOwnersSnapshotAtWar(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: planningInvadableOwnersGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
