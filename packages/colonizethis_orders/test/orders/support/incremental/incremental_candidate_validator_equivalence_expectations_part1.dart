part of 'incremental_candidate_validator_equivalence_expectations.dart';

void _moveBuilderOwnProvince() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'builder->own province',
  );
}

void _moveBuilderOtherGp() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: 'oldWorld|P3|0|0',
    ),
    label: 'builder->other GP province',
  );
}

void _moveExplorerMinor() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(
      unitId: 'u_explorer',
      destinationTileKey: 'oldWorld|P4|0|0',
    ),
    label: 'explorer->minor province',
  );
}

void _moveSpyOtherGp() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(
      unitId: 'u_spy',
      destinationTileKey: 'oldWorld|P3|0|0',
    ),
    label: 'spy->other GP province',
  );
}

void _moveMilitaryRegiment() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(
      unitId: 'u_pikemen',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'pikemen via MoveOrder',
  );
}

void _moveMissingUnit() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(
      unitId: 'unknown_unit',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'unknown unit',
  );
}

void _moveEmptyDestination() {
  iceExpectMoveOnCorpus(
    candidate: const MoveOrder(unitId: 'u_builder', destinationTileKey: ''),
    label: 'empty destination',
  );
}

void _moveXorWorkCascade() {
  final basePrefix = Orders(
    workOrdersByPlayerId: {
      IceIds.playerId: [
        const WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P2|0|0',
        ),
      ],
    },
  );
  iceExpectMoveOnCorpus(
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
      IceIds.playerId: [
        const MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
      ],
    },
  );
  iceExpectMoveOnCorpus(
    basePrefix: basePrefix,
    candidate: const MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: 'oldWorld|P2|0|0',
    ),
    label: 'builder w/ prior explorer move in basePrefix',
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
  final basePrefix = Orders(
    workOrdersByPlayerId: {
      IceIds.playerId: [
        const WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P2|0|0',
        ),
      ],
    },
  );
  iceExpectWorkOnCorpus(
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
  iceExpectArmyMoveOnCorpus(
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P2',
    ),
    label: 'own adjacent',
  );
}

void _armyMoveGpNoWar() {
  iceExpectArmyMoveOnCorpus(
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
      IceIds.playerId: [
        const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p2',
        ),
      ],
    },
  );
  iceExpectArmyMoveOnCorpus(
    basePrefix: basePrefix,
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P3',
    ),
    label: 'GP with declare war',
  );
}

void _armyMoveMinorNoWar() {
  iceExpectArmyMoveOnCorpus(
    candidate: const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P4',
    ),
    label: 'minor no war',
  );
}
