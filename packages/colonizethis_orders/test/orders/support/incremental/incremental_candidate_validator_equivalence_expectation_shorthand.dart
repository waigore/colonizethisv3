// Compact incremental equivalence expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'incremental_candidate_validator_equivalence_corpus_shorthand.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

BuildUnitOrder iceBuildUnit(String unitType) => BuildUnitOrder(
  unitType: unitType,
  isMilitary: true,
  spawnProvinceId: 'oldWorld|p1',
);

Orders iceExploreWorkPrefix(String unitId, String localProv) => Orders(
  workOrdersByPlayerId: {
    IceIds.playerId: [
      WorkOrder(
        unitId: unitId,
        target: kWorkTargetExplore,
        targetTileKey: iceTile(localProv),
      ),
    ],
  },
);

Orders iceMovePrefix(String unitId, String localProv) => Orders(
  moveOrdersByPlayerId: {
    IceIds.playerId: [
      MoveOrder(unitId: unitId, destinationTileKey: iceTile(localProv)),
    ],
  },
);

Orders iceDeclareWarPrefix(String targetFactionId) => Orders(
  diplomaticOrdersByPlayerId: {
    IceIds.playerId: [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetFactionId,
      ),
    ],
  },
);

void iceExpectBuildProbes(List<BuildUnitOrder> candidates) {
  final game = iceBuildCorpusGame();
  const topology = iceBuildCorpusTopology;
  const basePrefix = Orders();
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
  );
  for (final candidate in candidates) {
    expect(
      incremental.isBuildAccepted(candidate),
      fullPassBuildAccepted(
        game,
        topology,
        IceIds.playerId,
        basePrefix,
        candidate,
      ),
    );
  }
}

void iceExpectDiplomaticProbes(
  List<DiplomaticOrder> candidates, {
  Orders basePrefix = const Orders(),
  Game? game,
  MapTopology? topology,
}) {
  final resolvedGame = game ?? moveCorpusGame();
  final resolvedTopology = topology ?? moveCorpusTopology();
  final incremental = IncrementalCandidateValidator.forPlayer(
    game: resolvedGame,
    topology: resolvedTopology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
  );
  for (final candidate in candidates) {
    expect(
      incremental.isDiplomaticAccepted(candidate),
      fullPassDiplomaticAccepted(
        resolvedGame,
        resolvedTopology,
        IceIds.playerId,
        basePrefix,
        candidate,
      ),
    );
  }
}

void iceExpectPrefetchedArmyMove(ArmyMoveOrder candidate) {
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
  expect(
    withPrefetched.isArmyMoveAccepted(candidate),
    baseline.isArmyMoveAccepted(candidate),
  );
}

void iceExpectMoveBuilderOwnProvince() =>
    iceExpectMoveTo('u_builder', iceTile('P2'), label: 'builder->own province');

void iceExpectMoveBuilderOtherGp() =>
    iceExpectMoveTo('u_builder', iceTile('P3'), label: 'builder->other GP province');

void iceExpectMoveExplorerMinor() =>
    iceExpectMoveTo('u_explorer', iceTile('P4'), label: 'explorer->minor province');

void iceExpectMoveSpyOtherGp() =>
    iceExpectMoveTo('u_spy', iceTile('P3'), label: 'spy->other GP province');

void iceExpectMoveMilitaryRegiment() =>
    iceExpectMoveTo('u_pikemen', iceTile('P2'), label: 'pikemen via MoveOrder');

void iceExpectMoveMissingUnit() =>
    iceExpectMoveTo('unknown_unit', iceTile('P2'), label: 'unknown unit');

void iceExpectMoveEmptyDestination() =>
    iceExpectMoveTo('u_builder', '', label: 'empty destination');

void iceExpectMoveXorWorkCascade() {
  final tile = iceTile('P2');
  iceExpectMoveTo(
    'u_explorer',
    tile,
    label: 'move w/ existing work for same unit',
    basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
  );
}

void iceExpectMoveNonEmptyBasePrefix() {
  final tile = iceTile('P2');
  iceExpectMoveTo(
    'u_builder',
    tile,
    label: 'builder w/ prior explorer move in basePrefix',
    basePrefix: iceMovePrefix('u_explorer', 'P2'),
  );
}

void iceExpectBuildSingleCandidate() {
  expectBuildEquivalent(
    game: iceBuildCorpusGame(),
    topology: iceBuildCorpusTopology,
    playerId: IceIds.playerId,
    basePrefix: const Orders(),
    candidate: iceBuildUnit('pikemen'),
    label: 'single build candidate',
  );
}

void iceExpectBuildSuccessiveProbes() {
  iceExpectBuildProbes([
    iceBuildUnit('pikemen'),
    iceBuildUnit('musketeers'),
  ]);
}

void iceExpectWorkNonEmptyBasePrefix() {
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

void iceExpectDiplomaticNonEmptyBasePrefix() {
  iceExpectDiplomaticOnCorpus(
    basePrefix: iceDeclareWarPrefix('p2'),
    candidate: const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: 'p2',
    ),
    label: 'same-target non-economic conflict',
  );
}

void iceExpectDiplomaticSequentialProbes() {
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

void iceExpectPrefetchedFactionMembershipProbe() {
  iceExpectPrefetchedArmyMove(
    const ArmyMoveOrder(
      armyId: 'field_a',
      destinationProvinceId: 'oldWorld|P4',
    ),
  );
}

void iceExpectArmyMoveOwnAdjacent() =>
    iceExpectArmyMoveTo('field_a', 'P2', label: 'own adjacent');

void iceExpectArmyMoveGpNoWar() =>
    iceExpectArmyMoveTo('field_a', 'P3', label: 'GP no war');

void iceExpectArmyMoveGpDeclareWar() => iceExpectArmyMoveTo(
  'field_a',
  'P3',
  label: 'GP with declare war',
  basePrefix: iceDeclareWarPrefix('p2'),
);

void iceExpectArmyMoveMinorNoWar() =>
    iceExpectArmyMoveTo('field_a', 'P4', label: 'minor no war');

void iceExpectArmyMoveMissingArmy() =>
    iceExpectArmyMoveTo('unknown_army', 'P2', label: 'unknown army');

void iceExpectNavalMoveAdjacentSea() => iceExpectNavalMoveTo(
  'fleet_atSea',
  'oldWorld|sea2',
  label: 'sea1->sea2',
);

void iceExpectNavalMoveNonAdjacentSea() => iceExpectNavalMoveTo(
  'fleet_atSea',
  'oldWorld|seaZ',
  label: 'sea1->unknown',
);

void iceExpectNavalMoveUndock() => iceExpectNavalMoveTo(
  'fleet_inPort',
  'oldWorld|sea1',
  label: 'inPort->sea1',
);

void iceExpectNavalMoveMissingFleet() => iceExpectNavalMoveTo(
  'unknown_fleet',
  'oldWorld|sea1',
  label: 'unknown fleet',
);

void iceExpectNavalMissionPatrol() =>
    iceExpectNavalMissionFor('fleet_atSea', 'patrol', label: 'patrol owned');

void iceExpectNavalMissionBlockadeNoTarget() => iceExpectNavalMissionFor(
  'fleet_atSea',
  'blockade',
  label: 'blockade no target',
);

void iceExpectNavalMissionMissingFleet() => iceExpectNavalMissionFor(
  'unknown_fleet',
  'patrol',
  label: 'unknown fleet',
);
