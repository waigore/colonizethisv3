import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'incremental_candidate_validator_equivalence_naval_helpers.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

// Corpus shorthand wrappers for incremental equivalence expectations (Refs #3949).

abstract final class IceIds {
  static const playerId = 'p1';
  static const ow = 'oldWorld';
  static String prov(String local) => '$ow|$local';
}

Game iceBuildCorpusGame() => TestFixtures.gameWithSingleOwnedProvince(
  ownerPlayerId: IceIds.playerId,
  provinceId: IceIds.prov('p1'),
  treasury: 999,
);

const iceBuildCorpusTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: IceIds.ow,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

void iceExpectMoveOnCorpus({
  required MoveOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  expectMoveEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    candidate: candidate,
    label: label,
  );
}

void iceExpectWorkOnCorpus({
  required WorkOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  expectWorkEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    candidate: candidate,
    label: label,
  );
}

void iceExpectDiplomaticOnCorpus({
  required DiplomaticOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  expectDiplomaticEquivalent(
    game: moveCorpusGame(),
    topology: moveCorpusTopology(),
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    candidate: candidate,
    label: label,
  );
}

void iceExpectArmyMoveOnCorpus({
  required ArmyMoveOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  expectArmyMoveEquivalent(
    game: armyCorpusGame(),
    topology: armyCorpusTopology(),
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    candidate: candidate,
    label: label,
  );
}

void iceExpectNavalMoveOnCorpus({
  required NavalMoveOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  expectNavalMoveEquivalent(
    game: navalCorpusGame(),
    topology: navalCorpusTopology(),
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    candidate: candidate,
    label: label,
  );
}

void iceExpectNavalMissionOnCorpus({
  required NavalMissionOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  expectNavalMissionEquivalent(
    game: navalCorpusGame(),
    topology: navalCorpusTopology(),
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    candidate: candidate,
    label: label,
  );
}
