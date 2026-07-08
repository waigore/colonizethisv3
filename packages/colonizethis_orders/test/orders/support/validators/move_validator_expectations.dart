// Compact MoveValidator / ArmyMoveValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

/// Pins for [moveValidatorScenarios] rows.
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

OrderValidationResult _validateUnitMove({
  required Game game,
  required MapTopology topology,
  required String unitId,
  required String destinationTileKey,
  bool previousRejected = false,
}) {
  const validator = MoveValidator();
  return validator.validate(
    MoveOrder(unitId: unitId, destinationTileKey: destinationTileKey),
    game,
    'p1',
    moveValidatorTestContext(game, topology, 'p1'),
    const [],
    topology,
    previousRejected: previousRejected,
  );
}

OrderValidationResult _validateArmyMove({
  required Game game,
  required MapTopology topology,
  required String armyProvinceId,
  required String destinationProvinceId,
  List<DiplomaticOrder> draftOrders = const [],
}) {
  final view = buildPlayerView(game, topology, 'p1');
  const validator = ArmyMoveValidator();
  return validator.validate(
    ArmyMoveOrder(
      armyId: fieldArmyIdFor('p1', armyProvinceId),
      destinationProvinceId: destinationProvinceId,
    ),
    game,
    'p1',
    draftOrders,
    view,
    topology,
  );
}

void runMoveValidatorExpectation(MoveValidatorTarget target) {
  final owTopology = moveValidatorTestTwoProvinceTopology(_ow);
  switch (target) {
    case MoveValidatorTarget.civilianCannotMoveIntoOtherGp:
      final game = _twoProvinceUnitGame(
        unitType: kUnitTypeBuilder,
        unitId: 'u1',
        destOwnerId: 'p2',
        includeP2Player: true,
      );
      final result = _validateUnitMove(
        game: game,
        topology: owTopology,
        unitId: 'u1',
        destinationTileKey: '$_ow|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Invalid move'));
    case MoveValidatorTarget.militaryRegimentMoveOrderRejected:
      final game = _twoProvinceUnitGame(
        unitType: 'pikemen',
        unitId: 'u1',
        destOwnerId: 'p2',
        includeP2Player: true,
      );
      final result = _validateUnitMove(
        game: game,
        topology: owTopology,
        unitId: 'u1',
        destinationTileKey: '$_ow|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('army move'));
    case MoveValidatorTarget.armyMoveIntoOtherGpWithoutWar:
      final game = _twoProvinceArmyGame(
        destOwnerId: 'p2',
        includeP2Player: true,
      );
      final result = _validateArmyMove(
        game: game,
        topology: owTopology,
        armyProvinceId: '$_ow|P1',
        destinationProvinceId: '$_ow|P2',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('declare war'));
    case MoveValidatorTarget.civilianWorkerCannotMoveIntoMinor:
      final game = _twoProvinceUnitGame(
        unitType: kUnitTypeBuilder,
        unitId: 'u1',
        destOwnerId: 'minor1',
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );
      final result = _validateUnitMove(
        game: game,
        topology: owTopology,
        unitId: 'u1',
        destinationTileKey: '$_ow|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Invalid move'));
    case MoveValidatorTarget.explorerOntoMinor:
      final game = _twoProvinceUnitGame(
        unitType: kUnitTypeExplorer,
        unitId: 'u1',
        destOwnerId: 'minor1',
        unitTileKey: '$_ow|P1|0|0',
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );
      final result = _validateUnitMove(
        game: game,
        topology: owTopology,
        unitId: 'u1',
        destinationTileKey: '$_ow|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.accepted);
    case MoveValidatorTarget.spyOntoOtherGp:
      final game = _twoProvinceUnitGame(
        unitType: kUnitTypeSpy,
        unitId: 's1',
        destOwnerId: 'p2',
        includeP2Player: true,
        unitTileKey: '$_ow|P1|0|0',
      );
      final result = _validateUnitMove(
        game: game,
        topology: owTopology,
        unitId: 's1',
        destinationTileKey: '$_ow|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.accepted);
    case MoveValidatorTarget.explorerCrossRegionTribe:
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: _ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: _nw, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = _crossRegionTribeGame(unitType: kUnitTypeExplorer);
      final result = _validateUnitMove(
        game: game,
        topology: topology,
        unitId: 'u1',
        destinationTileKey: '$_nw|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.accepted);
    case MoveValidatorTarget.builderCrossRegionTribeInvalid:
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: _ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: _nw, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = _crossRegionTribeGame(unitType: kUnitTypeBuilder);
      final result = _validateUnitMove(
        game: game,
        topology: topology,
        unitId: 'u1',
        destinationTileKey: '$_nw|P2|0|0',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Invalid move');
    case MoveValidatorTarget.shortCircuitPreviousRejected:
      final game = _twoProvinceUnitGame(
        unitType: kUnitTypeBuilder,
        unitId: 'u1',
        destOwnerId: 'p1',
      );
      final result = _validateUnitMove(
        game: game,
        topology: owTopology,
        unitId: 'u1',
        destinationTileKey: '$_ow|P2|0|0',
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    case MoveValidatorTarget.armyMoveIntoMinorWithoutWar:
      final game = _twoProvinceArmyGame(
        destOwnerId: 'minor1',
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );
      final result = _validateArmyMove(
        game: game,
        topology: owTopology,
        armyProvinceId: '$_ow|P1',
        destinationProvinceId: '$_ow|P2',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('declare war'));
    case MoveValidatorTarget.armyMoveIntoGpWithDeclareWar:
      final game = _twoProvinceArmyGame(
        destOwnerId: 'p2',
        includeP2Player: true,
      );
      final result = _validateArmyMove(
        game: game,
        topology: owTopology,
        armyProvinceId: '$_ow|P1',
        destinationProvinceId: '$_ow|P2',
        draftOrders: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p2',
          ),
        ],
      );
      expect(result.status, OrderValidationStatus.accepted);
    case MoveValidatorTarget.armyMoveIntoMinorWithDeclareWar:
      final game = _twoProvinceArmyGame(
        destOwnerId: 'minor1',
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor1',
            capitalProvinceId: 'oldWorld|P2',
          ),
        ],
      );
      final result = _validateArmyMove(
        game: game,
        topology: owTopology,
        armyProvinceId: '$_ow|P1',
        destinationProvinceId: '$_ow|P2',
        draftOrders: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'minor1',
          ),
        ],
      );
      expect(result.status, OrderValidationStatus.accepted);
    case MoveValidatorTarget.armyMoveIntoTribeWithDeclareWar:
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: _nw, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: _nw, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(id: '$_nw|P1', regionId: _nw, ownerId: 'p1'),
              Province(id: '$_nw|P2', regionId: _nw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'pikemen',
                ownerId: 'p1',
                locationProvinceId: '$_nw|P1',
              ),
            ],
          ),
          armies: [moveValidatorTestFieldArmy(_nw, 'p1', 'P1', 'u1')],
          playerVisibilityByTile: const {
            'p1': {
              'newWorld|P1|0|0': 'fullyVisible',
              'newWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [
          Tribe(
            id: 'tribe1',
            displayName: 'Tribe1',
            capitalProvinceId: 'newWorld|P2',
          ),
        ],
        diplomacyRelations: const [],
      );
      final result = _validateArmyMove(
        game: game,
        topology: nwTopology,
        armyProvinceId: '$_nw|P1',
        destinationProvinceId: '$_nw|P2',
        draftOrders: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'tribe1',
          ),
        ],
      );
      expect(result.status, OrderValidationStatus.accepted);
    case MoveValidatorTarget.armyMoveIntoMinorTribeWithoutWar:
      final game = _twoProvinceArmyGame(
        destOwnerId: 'minor1',
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor1',
            capitalProvinceId: 'oldWorld|P2',
          ),
        ],
        tribes: const [],
      );
      final result = _validateArmyMove(
        game: game,
        topology: owTopology,
        armyProvinceId: '$_ow|P1',
        destinationProvinceId: '$_ow|P2',
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('declare war'));
      expect(result.reason, contains('Minor Nation or Tribe'));
  }
}
