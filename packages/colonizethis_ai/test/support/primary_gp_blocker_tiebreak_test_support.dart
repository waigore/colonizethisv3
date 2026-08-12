// Shared Game / snapshot fixtures for primary GP blocker tiebreak pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kPrimaryGpBlockerTiebreakGp1 = 'gp1';
const String kPrimaryGpBlockerTiebreakGp2 = 'gp2';
const String kPrimaryGpBlockerTiebreakGp3 = 'gp3';
const String kPrimaryGpBlockerTiebreakGp4 = 'gp4';

const List<Player> kPrimaryGpBlockerTiebreakFourGpRoster = [
  Player(id: kPrimaryGpBlockerTiebreakGp1, displayName: 'GP1', isHuman: false),
  Player(id: kPrimaryGpBlockerTiebreakGp2, displayName: 'GP2', isHuman: false),
  Player(id: kPrimaryGpBlockerTiebreakGp3, displayName: 'GP3', isHuman: false),
  Player(id: kPrimaryGpBlockerTiebreakGp4, displayName: 'GP4', isHuman: false),
];

Game primaryGpBlockerTiebreakGameForOwBlocker(List<Province> owProvinces) {
  return Game(
    id: 'g-2509-primary-blocker-tiebreak-ow',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 50,
        phase: TurnPhase.orders,
      ),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: const RegionData(),
    ),
    players: kPrimaryGpBlockerTiebreakFourGpRoster,
  );
}

Game primaryGpBlockerTiebreakGameForNwBlocker(List<Province> nwProvinces) {
  return Game(
    id: 'g-2509-primary-blocker-tiebreak-nw',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 110,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: kPrimaryGpBlockerTiebreakFourGpRoster,
  );
}

AIWorldSnapshot primaryGpBlockerTiebreakExpandSnapshotForOw({
  required List<String> invadableOw,
}) {
  return AIWorldSnapshot(
    playerId: kPrimaryGpBlockerTiebreakGp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 8,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

AIWorldSnapshot primaryGpBlockerTiebreakColonialSnapshotForNw({
  required List<String> invadableNw,
}) {
  return AIWorldSnapshot(
    playerId: kPrimaryGpBlockerTiebreakGp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}
