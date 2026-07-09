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
