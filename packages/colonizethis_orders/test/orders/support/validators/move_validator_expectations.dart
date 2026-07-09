// Compact MoveValidator / ArmyMoveValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_expectation_shorthand.dart';
import 'move_validator_test_support.dart';

/// Pins for [moveValidatorScenarios] rows.
part 'move_validator_expectations_cases_a.dart';
part 'move_validator_expectations_cases_b.dart';

enum MoveValidatorTarget {
  civilianCannotMoveIntoOtherGp,
  militaryRegimentMoveOrderRejected,
  armyMoveIntoOtherGpWithoutWar,
  civilianWorkerCannotMoveIntoMinor,
  explorerOntoMinor,
  spyOntoOtherGp,
  explorerCrossRegionTribe,
  builderCrossRegionTribeInvalid,
  shortCircuitPreviousRejected,
  armyMoveIntoMinorWithoutWar,
  armyMoveIntoGpWithDeclareWar,
  armyMoveIntoMinorWithDeclareWar,
  armyMoveIntoTribeWithDeclareWar,
  armyMoveIntoMinorTribeWithoutWar,
}

const _ow = 'oldWorld';
const _nw = 'newWorld';

Map<String, Map<String, String>> _p1FogPairVisibility({
  required String destRegion,
  required String destLocal,
}) =>
    {
      'p1': {
        '$_ow|P1|0|0': 'fullyVisible',
        '$destRegion|$destLocal|0|0': 'fogged',
      },
    };

Game _twoProvinceUnitGame({
  required String unitType,
  required String unitId,
  required String destOwnerId,
  bool includeP2Player = false,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  String? unitTileKey,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|P1', regionId: _ow, ownerId: 'p1'),
          Province(id: '$_ow|P2', regionId: _ow, ownerId: destOwnerId),
        ],
        units: [
          Unit(
            id: unitId,
            type: unitType,
            ownerId: 'p1',
            locationProvinceId: '$_ow|P1',
            tileKey: unitTileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: _p1FogPairVisibility(
        destRegion: _ow,
        destLocal: 'P2',
      ),
    ),
    players: [
      const Player(id: 'p1', displayName: 'P1', isHuman: true),
      if (includeP2Player)
        const Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: const [],
  );
}

Game _twoProvinceArmyGame({
  required String destOwnerId,
  bool includeP2Player = false,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|P1', regionId: _ow, ownerId: 'p1'),
          Province(id: '$_ow|P2', regionId: _ow, ownerId: destOwnerId),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$_ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [moveValidatorTestFieldArmy(_ow, 'p1', 'P1', 'u1')],
      playerVisibilityByTile: _p1FogPairVisibility(
        destRegion: _ow,
        destLocal: 'P2',
      ),
    ),
    players: [
      const Player(id: 'p1', displayName: 'P1', isHuman: true),
      if (includeP2Player)
        const Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: const [],
  );
}

Game _crossRegionTribeGame({required String unitType}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: '$_ow|P1', regionId: _ow, ownerId: 'p1')],
        units: [
          Unit(
            id: 'u1',
            type: unitType,
            ownerId: 'p1',
            locationProvinceId: '$_ow|P1',
            tileKey: '$_ow|P1|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [Province(id: '$_nw|P2', regionId: _nw, ownerId: 'tribe1')],
      ),
      playerVisibilityByTile: _p1FogPairVisibility(
        destRegion: _nw,
        destLocal: 'P2',
      ),
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe1')],
  );
}

MapTopology get owTopology => moveValidatorTestTwoProvinceTopology(_ow);

void runMoveValidatorExpectation(MoveValidatorTarget target) {
  switch (target) {
    case MoveValidatorTarget.civilianCannotMoveIntoOtherGp:
      _civilianCannotMoveIntoOtherGp();
    case MoveValidatorTarget.militaryRegimentMoveOrderRejected:
      _militaryRegimentMoveOrderRejected();
    case MoveValidatorTarget.armyMoveIntoOtherGpWithoutWar:
      _armyMoveIntoOtherGpWithoutWar();
    case MoveValidatorTarget.civilianWorkerCannotMoveIntoMinor:
      _civilianWorkerCannotMoveIntoMinor();
    case MoveValidatorTarget.explorerOntoMinor:
      _explorerOntoMinor();
    case MoveValidatorTarget.spyOntoOtherGp:
      _spyOntoOtherGp();
    case MoveValidatorTarget.explorerCrossRegionTribe:
      _explorerCrossRegionTribe();
    case MoveValidatorTarget.builderCrossRegionTribeInvalid:
      _builderCrossRegionTribeInvalid();
    case MoveValidatorTarget.shortCircuitPreviousRejected:
      _shortCircuitPreviousRejected();
    case MoveValidatorTarget.armyMoveIntoMinorWithoutWar:
      _armyMoveIntoMinorWithoutWar();
    case MoveValidatorTarget.armyMoveIntoGpWithDeclareWar:
      _armyMoveIntoGpWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoMinorWithDeclareWar:
      _armyMoveIntoMinorWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoTribeWithDeclareWar:
      _armyMoveIntoTribeWithDeclareWar();
    case MoveValidatorTarget.armyMoveIntoMinorTribeWithoutWar:
      _armyMoveIntoMinorTribeWithoutWar();
  }
}

