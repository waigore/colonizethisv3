/// Phase-planner dispatch Game / snapshot scaffolds for COLONIAL support
/// pins (Refs #3977 / #3997).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';
import 'colonial_phase_planner_test_support_core.dart';

export 'colonial_phase_planner_test_support_dispatch_develop.dart';

/// Phase-planner dispatch COLONIAL-lite Game: turn ≥ 120, OW near quota
/// scaffold with a tribe-owned NW province (Refs #3977).
Game buildPhasePlannerDispatchColonialLiteGame({
  int turnNumber = kObserverColonialLiteMinTurn + 5,
  int regimentCount = 6,
  int ownTreasury = 9999,
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    gameId: 'g-2509-phase-planner-dispatch-expand-t$turnNumber',
    oldWorldProvinces: const [
      Province(
        id: kColonialPhaseDispatchOwProvGp1,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseGp1,
      ),
      Province(
        id: kColonialPhaseDispatchOwProvMinor,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseMinor1,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: kColonialPhaseNwProvTribeA,
        regionId: kNewWorldRegionId,
        ownerId: kColonialPhaseTribe1,
      ),
    ],
    armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: kColonialPhaseMinor1, displayName: 'Minor1'),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Phase-planner dispatch COLONIAL Game: OW at quota with NW invadable
/// tribe province and Home Army regiment count (Refs #3977).
Game buildPhasePlannerDispatchColonialGame({
  int regimentCount = 6,
  int ownTreasury = 9999,
}) {
  return buildColonialPhaseGame(
    turnNumber: 130,
    gameId: 'g-2509-phase-planner-dispatch-colonial',
    oldWorldProvinces: const [
      Province(
        id: kColonialPhaseDispatchOwProvGp1,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseGp1,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: kColonialPhaseNwProvTribeA,
        regionId: kNewWorldRegionId,
        ownerId: kColonialPhaseTribe1,
      ),
    ],
    armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Phase-planner dispatch EXPAND Game: below-quota OW minor frontier,
/// empty NW so routing cannot flip to COLONIAL-lite / COLONIAL
/// (Refs #3997).
Game buildPhasePlannerDispatchExpandGame({
  int turnNumber = 50,
  int regimentCount = 6,
  int ownTreasury = 9999,
  List<Province> newWorldProvinces = const [],
}) {
  return Game(
    id: 'g-2509-phase-planner-dispatch-expand-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: kColonialPhaseDispatchOwProvGp1,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
          Province(
            id: kColonialPhaseDispatchOwProvMinor,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseMinor1,
          ),
        ],
      ),
      newWorld: RegionData(provinces: newWorldProvinces),
      armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    ),
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: kColonialPhaseMinor1, displayName: 'Minor1'),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}
