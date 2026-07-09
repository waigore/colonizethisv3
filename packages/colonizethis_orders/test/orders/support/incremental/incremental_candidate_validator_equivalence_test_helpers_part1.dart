part of 'incremental_candidate_validator_equivalence_test_helpers.dart';

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

Game moveCorpusGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g_move_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_spy',
            type: kUnitTypeSpy,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_pikemen',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|P1': ['$ow|P1|0|0'],
          '$ow|P2': ['$ow|P2|0|0'],
          '$ow|P3': ['$ow|P3|0|0'],
          '$ow|P4': ['$ow|P4|0|0'],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          '$ow|P1|0|0': 'fullyVisible',
          '$ow|P2|0|0': 'fogged',
          '$ow|P3|0|0': 'fogged',
          '$ow|P4|0|0': 'fogged',
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
}

MapTopology moveCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
}

Game armyCorpusGame() {
  const ow = 'oldWorld';
  Army field(String id, String stationed, String regimentId) => Army(
    id: id,
    ownerId: 'p1',
    regionId: ow,
    stationedProvinceId: stationed,
    regimentUnitIds: [regimentId],
    isHomeArmy: false,
  );
  return Game(
    id: 'g_army_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [field('field_a', '$ow|P1', 'r1')],
      playerVisibilityByTile: const {
        'p1': {
          '$ow|P1|0|0': 'fullyVisible',
          '$ow|P2|0|0': 'fogged',
          '$ow|P3|0|0': 'fogged',
          '$ow|P4|0|0': 'fogged',
        },
      },
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|P1': ['$ow|P1|0|0'],
          '$ow|P2': ['$ow|P2|0|0'],
          '$ow|P3': ['$ow|P3|0|0'],
          '$ow|P4': ['$ow|P4|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    diplomacyRelations: const [],
  );
}

MapTopology armyCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P2'),
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P3'),
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P4'),
    ],
  );
}