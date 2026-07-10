// Shared incremental/full-pass equivalence helpers (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

bool _fullPassAddOrderAccepted(
  Orders basePrefix,
  OrderValidationResult Function(OrderEngine engine) add,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return add(engine).isAccepted;
}

bool fullPassMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  MoveOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) =>
          engine.addMoveOrderWithContext(game, topology, playerId, candidate),
    );

bool fullPassArmyMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  ArmyMoveOrder candidate,
) {
  final merged = applyArmyMoveOrderForPlayer(basePrefix, playerId, candidate);
  final engine = OrderEngine(initialOrders: merged);
  final results = engine.validatePlayerOrdersWithContext(
    game,
    topology,
    playerId,
  );
  if (results.isEmpty) return false;
  return results.every((r) => r.isAccepted);
}

bool fullPassBuildAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  BuildUnitOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) =>
          engine.addBuildOrderWithContext(game, topology, playerId, candidate),
    );

bool fullPassWorkAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) => engine.addWorkOrderWithContext(
        game,
        topology,
        playerId,
        candidate,
        tileMapByRegion: tileMapByRegion,
      ),
    );

bool fullPassDiplomaticAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  DiplomaticOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) => engine.addDiplomaticOrderWithContext(
        game,
        topology,
        playerId,
        candidate,
      ),
    );

IncrementalCandidateValidator _iceValidatorFor({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    IncrementalCandidateValidator.forPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      basePrefix: basePrefix,
      tileMapByRegion: tileMapByRegion,
    );

void _expectIncrementalMatchesFullPass({
  required bool fullPass,
  required bool incremental,
  required String family,
  required String label,
}) {
  expect(
    incremental,
    equals(fullPass),
    reason:
        '$family candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectCandidateFamilyEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required String family,
  required String label,
  required bool Function() fullPass,
  required bool Function(IncrementalCandidateValidator validator) incremental,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  _expectIncrementalMatchesFullPass(
    fullPass: fullPass(),
    incremental: incremental(
      _iceValidatorFor(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: basePrefix,
        tileMapByRegion: tileMapByRegion,
      ),
    ),
    family: family,
    label: label,
  );
}

void expectMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required MoveOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Move',
    label: label,
    fullPass: () => fullPassMoveAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isMoveAccepted(candidate),
  );
}

void expectArmyMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required ArmyMoveOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Army move',
    label: label,
    fullPass: () => fullPassArmyMoveAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isArmyMoveAccepted(candidate),
  );
}

void expectBuildEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required BuildUnitOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Build',
    label: label,
    fullPass: () => fullPassBuildAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isBuildAccepted(candidate),
  );
}

void expectWorkEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required WorkOrder candidate,
  required String label,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Work',
    label: label,
    tileMapByRegion: tileMapByRegion,
    fullPass: () => fullPassWorkAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
      tileMapByRegion: tileMapByRegion,
    ),
    incremental: (validator) => validator.isWorkAccepted(candidate),
  );
}

void expectDiplomaticEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required DiplomaticOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Diplomatic',
    label: label,
    fullPass: () => fullPassDiplomaticAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isDiplomaticAccepted(candidate),
  );
}

const _iceCorpusOw = 'oldWorld';

List<Province> _iceCorpusProvinces() => const [
      Province(id: '$_iceCorpusOw|P1', regionId: _iceCorpusOw, ownerId: 'p1'),
      Province(id: '$_iceCorpusOw|P2', regionId: _iceCorpusOw, ownerId: 'p1'),
      Province(id: '$_iceCorpusOw|P3', regionId: _iceCorpusOw, ownerId: 'p2'),
      Province(id: '$_iceCorpusOw|P4', regionId: _iceCorpusOw, ownerId: 'minor1'),
    ];

Map<String, Map<String, String>> _iceCorpusVisibility() => const {
      'p1': {
        '$_iceCorpusOw|P1|0|0': 'fullyVisible',
        '$_iceCorpusOw|P2|0|0': 'fogged',
        '$_iceCorpusOw|P3|0|0': 'fogged',
        '$_iceCorpusOw|P4|0|0': 'fogged',
      },
    };

Map<String, Map<String, List<String>>> _iceCorpusTileKeys() => const {
      _iceCorpusOw: {
        '$_iceCorpusOw|P1': ['$_iceCorpusOw|P1|0|0'],
        '$_iceCorpusOw|P2': ['$_iceCorpusOw|P2|0|0'],
        '$_iceCorpusOw|P3': ['$_iceCorpusOw|P3|0|0'],
        '$_iceCorpusOw|P4': ['$_iceCorpusOw|P4|0|0'],
      },
    };

List<TopologyNode> _iceCorpusTopologyNodes() => const [
      TopologyNode(id: '$_iceCorpusOw|P1', regionId: _iceCorpusOw, type: TopologyNodeType.province),
      TopologyNode(id: '$_iceCorpusOw|P2', regionId: _iceCorpusOw, type: TopologyNodeType.province),
      TopologyNode(id: '$_iceCorpusOw|P3', regionId: _iceCorpusOw, type: TopologyNodeType.province),
      TopologyNode(id: '$_iceCorpusOw|P4', regionId: _iceCorpusOw, type: TopologyNodeType.province),
    ];

Game _iceCorpusGame({
  required String id,
  required RegionData oldWorld,
  List<Army> armies = const [],
}) =>
    Game(
      id: id,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: oldWorld,
        newWorld: const RegionData(),
        armies: armies,
        tileKeysByRegionAndProvince: _iceCorpusTileKeys(),
        playerVisibilityByTile: _iceCorpusVisibility(),
      ),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    );

Game moveCorpusGame() {
  return _iceCorpusGame(
    id: 'g_move_eq',
    oldWorld: RegionData(
      provinces: _iceCorpusProvinces(),
      units: [
        Unit(
          id: 'u_builder',
          type: kUnitTypeBuilder,
          ownerId: 'p1',
          locationProvinceId: '$_iceCorpusOw|P1',
          tileKey: '$_iceCorpusOw|P1|0|0',
        ),
        Unit(
          id: 'u_explorer',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: '$_iceCorpusOw|P1',
          tileKey: '$_iceCorpusOw|P1|0|0',
        ),
        Unit(
          id: 'u_spy',
          type: kUnitTypeSpy,
          ownerId: 'p1',
          locationProvinceId: '$_iceCorpusOw|P1',
          tileKey: '$_iceCorpusOw|P1|0|0',
        ),
        Unit(
          id: 'u_pikemen',
          type: 'pikemen',
          ownerId: 'p1',
          locationProvinceId: '$_iceCorpusOw|P1',
        ),
      ],
    ),
  );
}

MapTopology moveCorpusTopology() {
  return MapTopology(
    nodes: _iceCorpusTopologyNodes(),
    edges: const [],
  );
}

Game armyCorpusGame() {
  Army field(String id, String stationed, String regimentId) => Army(
    id: id,
    ownerId: 'p1',
    regionId: _iceCorpusOw,
    stationedProvinceId: stationed,
    regimentUnitIds: [regimentId],
    isHomeArmy: false,
  );
  return _iceCorpusGame(
    id: 'g_army_eq',
    oldWorld: RegionData(
      provinces: _iceCorpusProvinces(),
      units: [
        Unit(
          id: 'r1',
          type: 'pikemen',
          ownerId: 'p1',
          locationProvinceId: '$_iceCorpusOw|P1',
        ),
      ],
    ),
    armies: [field('field_a', '$_iceCorpusOw|P1', 'r1')],
  );
}

MapTopology armyCorpusTopology() {
  return MapTopology(
    nodes: _iceCorpusTopologyNodes(),
    edges: const [
      TopologyEdge(id1: '$_iceCorpusOw|P1', id2: '$_iceCorpusOw|P2'),
      TopologyEdge(id1: '$_iceCorpusOw|P1', id2: '$_iceCorpusOw|P3'),
      TopologyEdge(id1: '$_iceCorpusOw|P1', id2: '$_iceCorpusOw|P4'),
    ],
  );
}
