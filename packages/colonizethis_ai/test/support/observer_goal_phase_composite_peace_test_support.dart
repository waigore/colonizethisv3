// Shared Game / snapshot fixtures for composite peace-target pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kObserverGoalPhaseCompositePeaceGpOwn = 'gp_own';
const String kObserverGoalPhaseCompositePeaceGpOther = 'gp_other';
const String kObserverGoalPhaseCompositePeaceMinorZeta = 'minor_zeta';

Game observerGoalPhaseCompositePeacePristineOwProvinces(int count) {
  return Game(
    id: 'g-2509-composite-pristine-$count',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: [
        for (var i = 1; i <= count; i++)
          Province(
            id: 'oldWorld|${kObserverGoalPhaseCompositePeaceGpOwn}_$i',
            regionId: 'oldWorld',
            ownerId: kObserverGoalPhaseCompositePeaceGpOwn,
          ),
      ]),
      newWorld: const RegionData(),
      armies: [],
    ),
    players: [
      Player(
        id: kObserverGoalPhaseCompositePeaceGpOwn,
        displayName: 'GP_OWN',
        isHuman: false,
      ),
      Player(
        id: kObserverGoalPhaseCompositePeaceGpOther,
        displayName: 'GP_OTHER',
        isHuman: false,
      ),
    ],
    minorNations: const [],
    tribes: const [],
    diplomacyRelations: const [],
  );
}

Game observerGoalPhaseCompositePeaceZeroRegimentAtWarGame() {
  return Game(
    id: 'g-2509-composite-zero-reg',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: [
        for (var i = 1; i <= 6; i++)
          Province(
            id: 'oldWorld|${kObserverGoalPhaseCompositePeaceGpOwn}_$i',
            regionId: 'oldWorld',
            ownerId: kObserverGoalPhaseCompositePeaceGpOwn,
          ),
        for (var i = 1; i <= 6; i++)
          Province(
            id: 'oldWorld|${kObserverGoalPhaseCompositePeaceGpOther}_$i',
            regionId: 'oldWorld',
            ownerId: kObserverGoalPhaseCompositePeaceGpOther,
          ),
        const Province(
          id: 'oldWorld|minor_invadable',
          regionId: 'oldWorld',
          ownerId: kObserverGoalPhaseCompositePeaceMinorZeta,
        ),
      ]),
      newWorld: const RegionData(),
      armies: [],
    ),
    players: [
      Player(
        id: kObserverGoalPhaseCompositePeaceGpOwn,
        displayName: 'GP_OWN',
        isHuman: false,
      ),
      Player(
        id: kObserverGoalPhaseCompositePeaceGpOther,
        displayName: 'GP_OTHER',
        isHuman: false,
      ),
    ],
    minorNations: const [
      MinorNation(
        id: kObserverGoalPhaseCompositePeaceMinorZeta,
        displayName: 'MZ',
      ),
    ],
    tribes: const [],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: kObserverGoalPhaseCompositePeaceGpOwn,
        factionId2: kObserverGoalPhaseCompositePeaceGpOther,
        state: RelationState.atWar,
        score: 30,
      ),
      DiplomacyRelation(
        factionId1: kObserverGoalPhaseCompositePeaceGpOwn,
        factionId2: kObserverGoalPhaseCompositePeaceMinorZeta,
        state: RelationState.atWar,
        score: 10,
      ),
    ],
  );
}

AIWorldSnapshot observerGoalPhaseCompositePeaceSnapshotFor({
  required String playerId,
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31 - oldWorldProvincesOwned,
      invadableProvinceIdsSorted: const [
        'oldWorld|minor_invadable',
        'oldWorld|gp_other_1',
      ],
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(),
    relations: {},
  );
}
