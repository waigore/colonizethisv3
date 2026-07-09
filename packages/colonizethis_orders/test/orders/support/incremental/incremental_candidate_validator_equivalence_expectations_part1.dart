part of 'incremental_candidate_validator_equivalence_expectations.dart';

void _moveBuilderOwnProvince() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'builder->own province',
  );
}

void _moveBuilderOtherGp() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: 'oldWorld|P3|0|0',
    ),
    label: 'builder->other GP province',
  );
}

void _moveExplorerMinor() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(
      unitId: 'u_explorer',
      destinationTileKey: 'oldWorld|P4|0|0',
    ),
    label: 'explorer->minor province',
  );
}

void _moveSpyOtherGp() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(
      unitId: 'u_spy',
      destinationTileKey: 'oldWorld|P3|0|0',
    ),
    label: 'spy->other GP province',
  );
}

void _moveMilitaryRegiment() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(
      unitId: 'u_pikemen',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'pikemen via MoveOrder',
  );
}

void _moveMissingUnit() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(
      unitId: 'unknown_unit',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'unknown unit',
  );
}

void _moveEmptyDestination() {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const MoveOrder(unitId: 'u_builder', destinationTileKey: ''),
    label: 'empty destination',
  );
}

void _moveXorWorkCascade() {
  final basePrefix = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P2|0|0',
        ),
      ],
    },
  );
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: basePrefix,
    candidate: const MoveOrder(
      unitId: 'u_explorer',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'move w/ existing work for same unit',
  );
}

void _moveNonEmptyBasePrefix() {
  final basePrefix = Orders(
    moveOrdersByPlayerId: {
      'p1': [
        const MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
      ],
    },
  );
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: basePrefix,
    candidate: const MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'builder w/ prior explorer move in basePrefix',
  );
}

Game _buildCorpusGame() => TestFixtures.gameWithSingleOwnedProvince(
  ownerPlayerId: 'p1',
  provinceId: 'oldWorld|p1',
  treasury: 999,
);

const _buildCorpusTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

void _buildSingleCandidate() {
  expectBuildEquivalent(
    game: _buildCorpusGame(),
    topology: _buildCorpusTopology,
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const BuildUnitOrder(
      unitType: 'pikemen',
      isMilitary: true,
      spawnProvinceId: 'oldWorld|p1',
    ),
    label: 'single build candidate',
  );
}

void _buildSuccessiveProbes() {
  final game = _buildCorpusGame();
  const topology = _buildCorpusTopology;
  const basePrefix = Orders();
  const candidateA = BuildUnitOrder(
    unitType: 'pikemen',
    isMilitary: true,
    spawnProvinceId: 'oldWorld|p1',
  );
  const candidateB = BuildUnitOrder(
    unitType: 'musketeers',
    isMilitary: true,
    spawnProvinceId: 'oldWorld|p1',
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: 'p1',
    basePrefix: basePrefix,
  );
  expect(
    incremental.isBuildAccepted(candidateA),
    fullPassBuildAccepted(game, topology, 'p1', basePrefix, candidateA),
  );
  expect(
    incremental.isBuildAccepted(candidateB),
    fullPassBuildAccepted(game, topology, 'p1', basePrefix, candidateB),
  );
}

void _workNonEmptyBasePrefix() {
  final basePrefix = Orders(
    workOrdersByPlayerId: {
      'p1': [
        const WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P2|0|0',
        ),
      ],
    },
  );
  expectWorkEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: basePrefix,
    candidate: const WorkOrder(
      unitId: 'u_explorer',
      target: kWorkTargetExplore,
      targetTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'duplicate work unit with basePrefix',
  );
}

void _diplomaticNonEmptyBasePrefix() {
  final basePrefix = Orders(
    diplomaticOrdersByPlayerId: {
      'p1': [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
  expectDiplomaticEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: 'p1',
    basePrefix: basePrefix,
    candidate: const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: 'p2',
    ),
    label: 'same-target non-economic conflict',
  );
}

void _diplomaticSequentialProbes() {
  final game = moveCorpusGame();
  final topology = moveCorpusTopology();
  final basePrefix = Orders(
    diplomaticOrdersByPlayerId: {
      'p1': [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
  const candidateA = DiplomaticOrder(
    type: DiplomaticOrderType.alliance,
    targetFactionId: 'p2',
  );
  const candidateB = DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: 'p3',
  );
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: 'p1',
    basePrefix: basePrefix,
  );
  expect(
    incremental.isDiplomaticAccepted(candidateA),
    fullPassDiplomaticAccepted(game, topology, 'p1', basePrefix, candidateA),
  );
  expect(
    incremental.isDiplomaticAccepted(candidateB),
    fullPassDiplomaticAccepted(game, topology, 'p1', basePrefix, candidateB),
  );
  expect(
    incremental.isDiplomaticAccepted(candidateA),
    fullPassDiplomaticAccepted(game, topology, 'p1', basePrefix, candidateA),
  );
}

void _prefetchedFactionMembership() {
  final game = armyCorpusGame();
  final topology = armyCorpusTopology();
  const playerId = 'p1';
  const basePrefix = Orders();
  final prefetched = DiplomacyFactionMembership.from(game);
  final baseline = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
  );
  final withPrefetched = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    factionMembership: prefetched,
  );
  const armyMove = ArmyMoveOrder(
    armyId: 'field_a',
    destinationProvinceId: 'oldWorld|P4',
  );
  expect(
    withPrefetched.isArmyMoveAccepted(armyMove),
    baseline.isArmyMoveAccepted(armyMove),
  );
}

void _armyMoveOwnAdjacent() {
  expectArmyMoveEquivalent(
    game: armyCorpusGame(),
    topology: armyCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P2',
    ),
    label: 'own adjacent',
  );
}

void _armyMoveGpNoWar() {
  expectArmyMoveEquivalent(
    game: armyCorpusGame(),
    topology: armyCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P3',
    ),
    label: 'GP no war',
  );
}

void _armyMoveGpDeclareWar() {
  final basePrefix = Orders(
    diplomaticOrdersByPlayerId: {
      'p1': [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
  expectArmyMoveEquivalent(
    game: armyCorpusGame(),
    topology: armyCorpusTopology(),
    playerId: 'p1',
    basePrefix: basePrefix,
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P3',
    ),
    label: 'GP with declare war',
  );
}

void _armyMoveMinorNoWar() {
  expectArmyMoveEquivalent(
    game: armyCorpusGame(),
    topology: armyCorpusTopology(),
    playerId: 'p1',
    basePrefix: const Orders(),
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P4',
    ),
    label: 'minor no war',
  );
}
