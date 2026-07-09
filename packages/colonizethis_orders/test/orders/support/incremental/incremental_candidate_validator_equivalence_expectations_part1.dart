part of 'incremental_candidate_validator_equivalence_expectations.dart';

void _moveBuilderOwnProvince() {
  iceExpectMoveTo(
    'u_builder',
    iceTile('P2'),
    label: 'builder->own province',
  );
}

void _moveBuilderOtherGp() {
  iceExpectMoveTo(
    'u_builder',
    iceTile('P3'),
    label: 'builder->other GP province',
  );
}

void _moveExplorerMinor() {
  iceExpectMoveTo(
    'u_explorer',
    iceTile('P4'),
    label: 'explorer->minor province',
  );
}

void _moveSpyOtherGp() {
  iceExpectMoveTo(
    'u_spy',
    iceTile('P3'),
    label: 'spy->other GP province',
  );
}

void _moveMilitaryRegiment() {
  iceExpectMoveTo(
    'u_pikemen',
    iceTile('P2'),
    label: 'pikemen via MoveOrder',
  );
}

void _moveMissingUnit() {
  iceExpectMoveTo(
    'unknown_unit',
    iceTile('P2'),
    label: 'unknown unit',
  );
}

void _moveEmptyDestination() {
  iceExpectMoveTo('u_builder', '', label: 'empty destination');
}

void _moveXorWorkCascade() {
  final tile = iceTile('P2');
  final basePrefix = Orders(
    workOrdersByPlayerId: {
      IceIds.playerId: [
        WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: tile,
        ),
      ],
    },
  );
  iceExpectMoveTo(
    'u_explorer',
    tile,
    label: 'move w/ existing work for same unit',
    basePrefix: basePrefix,
  );
}

void _moveNonEmptyBasePrefix() {
  final tile = iceTile('P2');
  final basePrefix = Orders(
    moveOrdersByPlayerId: {
      IceIds.playerId: [
        MoveOrder(unitId: 'u_explorer', destinationTileKey: tile),
      ],
    },
  );
  iceExpectMoveTo(
    'u_builder',
    tile,
    label: 'builder w/ prior explorer move in basePrefix',
    basePrefix: basePrefix,
  );
}

void _buildSingleCandidate() {
  expectBuildEquivalent(
    game: iceBuildCorpusGame(),
    topology: iceBuildCorpusTopology,
    playerId: IceIds.playerId,
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
  final game = iceBuildCorpusGame();
  const topology = iceBuildCorpusTopology;
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
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
  );
  expect(
    incremental.isBuildAccepted(candidateA),
    fullPassBuildAccepted(game, topology, IceIds.playerId, basePrefix, candidateA),
  );
  expect(
    incremental.isBuildAccepted(candidateB),
    fullPassBuildAccepted(game, topology, IceIds.playerId, basePrefix, candidateB),
  );
}

void _workNonEmptyBasePrefix() {
  final tile = iceTile('P2');
  final basePrefix = Orders(
    workOrdersByPlayerId: {
      IceIds.playerId: [
        WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: tile,
        ),
      ],
    },
  );
  iceExpectWorkOnCorpus(
    basePrefix: basePrefix,
    candidate: WorkOrder(
      unitId: 'u_explorer',
      target: kWorkTargetExplore,
      targetTileKey: tile,
    ),
    label: 'duplicate work unit with basePrefix',
  );
}

void _diplomaticNonEmptyBasePrefix() {
  final basePrefix = Orders(
    diplomaticOrdersByPlayerId: {
      IceIds.playerId: [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
  iceExpectDiplomaticOnCorpus(
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
      IceIds.playerId: [
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
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
  );
  expect(
    incremental.isDiplomaticAccepted(candidateA),
    fullPassDiplomaticAccepted(
      game,
      topology,
      IceIds.playerId,
      basePrefix,
      candidateA,
    ),
  );
  expect(
    incremental.isDiplomaticAccepted(candidateB),
    fullPassDiplomaticAccepted(
      game,
      topology,
      IceIds.playerId,
      basePrefix,
      candidateB,
    ),
  );
  expect(
    incremental.isDiplomaticAccepted(candidateA),
    fullPassDiplomaticAccepted(
      game,
      topology,
      IceIds.playerId,
      basePrefix,
      candidateA,
    ),
  );
}

void _prefetchedFactionMembership() {
  final game = armyCorpusGame();
  final topology = armyCorpusTopology();
  const basePrefix = Orders();
  final prefetched = DiplomacyFactionMembership.from(game);
  final baseline = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
  );
  final withPrefetched = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
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
  iceExpectArmyMoveTo('field_a', 'P2', label: 'own adjacent');
}

void _armyMoveGpNoWar() {
  iceExpectArmyMoveTo('field_a', 'P3', label: 'GP no war');
}

void _armyMoveGpDeclareWar() {
  final basePrefix = Orders(
    diplomaticOrdersByPlayerId: {
      IceIds.playerId: [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
  iceExpectArmyMoveTo(
    'field_a',
    'P3',
    label: 'GP with declare war',
    basePrefix: basePrefix,
  );
}

void _armyMoveMinorNoWar() {
  iceExpectArmyMoveTo('field_a', 'P4', label: 'minor no war');
}
