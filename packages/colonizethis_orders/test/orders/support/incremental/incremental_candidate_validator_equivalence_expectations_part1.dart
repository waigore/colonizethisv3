part of 'incremental_candidate_validator_equivalence_expectations.dart';

void _moveBuilderOwnProvince() {
  iceExpectMoveTo('u_builder', iceTile('P2'), label: 'builder->own province');
}

void _moveBuilderOtherGp() {
  iceExpectMoveTo('u_builder', iceTile('P3'), label: 'builder->other GP province');
}

void _moveExplorerMinor() {
  iceExpectMoveTo('u_explorer', iceTile('P4'), label: 'explorer->minor province');
}

void _moveSpyOtherGp() {
  iceExpectMoveTo('u_spy', iceTile('P3'), label: 'spy->other GP province');
}

void _moveMilitaryRegiment() {
  iceExpectMoveTo('u_pikemen', iceTile('P2'), label: 'pikemen via MoveOrder');
}

void _moveMissingUnit() {
  iceExpectMoveTo('unknown_unit', iceTile('P2'), label: 'unknown unit');
}

void _moveEmptyDestination() {
  iceExpectMoveTo('u_builder', '', label: 'empty destination');
}

void _moveXorWorkCascade() {
  final tile = iceTile('P2');
  iceExpectMoveTo(
    'u_explorer',
    tile,
    label: 'move w/ existing work for same unit',
    basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
  );
}

void _moveNonEmptyBasePrefix() {
  final tile = iceTile('P2');
  iceExpectMoveTo(
    'u_builder',
    tile,
    label: 'builder w/ prior explorer move in basePrefix',
    basePrefix: iceMovePrefix('u_explorer', 'P2'),
  );
}

void _buildSingleCandidate() {
  expectBuildEquivalent(
    game: iceBuildCorpusGame(),
    topology: iceBuildCorpusTopology,
    playerId: IceIds.playerId,
    basePrefix: const Orders(),
    candidate: iceBuildUnit('pikemen'),
    label: 'single build candidate',
  );
}

void _buildSuccessiveProbes() {
  iceExpectBuildProbes([
    iceBuildUnit('pikemen'),
    iceBuildUnit('musketeers'),
  ]);
}

void _workNonEmptyBasePrefix() {
  final tile = iceTile('P2');
  iceExpectWorkOnCorpus(
    basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
    candidate: WorkOrder(
      unitId: 'u_explorer',
      target: kWorkTargetExplore,
      targetTileKey: tile,
    ),
    label: 'duplicate work unit with basePrefix',
  );
}

void _diplomaticNonEmptyBasePrefix() {
  iceExpectDiplomaticOnCorpus(
    basePrefix: iceDeclareWarPrefix('p2'),
    candidate: const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: 'p2',
    ),
    label: 'same-target non-economic conflict',
  );
}

void _diplomaticSequentialProbes() {
  iceExpectDiplomaticProbes(
    [
      const DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'p2',
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'p3',
      ),
      const DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'p2',
      ),
    ],
    basePrefix: iceDeclareWarPrefix('p2'),
  );
}

void _prefetchedFactionMembership() {
  iceExpectPrefetchedArmyMove(
    const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P4',
    ),
  );
}

void _armyMoveOwnAdjacent() {
  iceExpectArmyMoveTo('field_a', 'P2', label: 'own adjacent');
}

void _armyMoveGpNoWar() {
  iceExpectArmyMoveTo('field_a', 'P3', label: 'GP no war');
}

void _armyMoveGpDeclareWar() {
  iceExpectArmyMoveTo(
    'field_a',
    'P3',
    label: 'GP with declare war',
    basePrefix: iceDeclareWarPrefix('p2'),
  );
}

void _armyMoveMinorNoWar() {
  iceExpectArmyMoveTo('field_a', 'P4', label: 'minor no war');
}
