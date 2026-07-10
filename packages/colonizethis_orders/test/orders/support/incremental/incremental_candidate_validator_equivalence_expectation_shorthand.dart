// Compact incremental equivalence expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'incremental_candidate_validator_equivalence_test_helpers.dart';

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

String iceTile(String localProv) => '${IceIds.prov(localProv)}|0|0';

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

void iceExpectMoveOnCorpus({
  required MoveOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  final game = moveCorpusGame();
  final topology = moveCorpusTopology();
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    family: 'Move',
    label: label,
    fullPass: () =>
        fullPassMoveAccepted(game, topology, IceIds.playerId, basePrefix, candidate),
    incremental: (validator) => validator.isMoveAccepted(candidate),
  );
}

void iceExpectArmyMoveOnCorpus({
  required ArmyMoveOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  final game = armyCorpusGame();
  final topology = armyCorpusTopology();
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    family: 'Army move',
    label: label,
    fullPass: () => fullPassArmyMoveAccepted(
      game,
      topology,
      IceIds.playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isArmyMoveAccepted(candidate),
  );
}

void iceExpectNavalMoveOnCorpus({
  required NavalMoveOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  final game = navalCorpusGame();
  final topology = navalCorpusTopology();
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    family: 'Naval move',
    label: label,
    fullPass: () => fullPassNavalMoveAccepted(
      game,
      topology,
      IceIds.playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isNavalMoveAccepted(candidate),
  );
}

void iceExpectNavalMissionOnCorpus({
  required NavalMissionOrder candidate,
  required String label,
  Orders basePrefix = const Orders(),
}) {
  final game = navalCorpusGame();
  final topology = navalCorpusTopology();
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    family: 'Naval mission',
    label: label,
    fullPass: () => fullPassNavalMissionAccepted(
      game,
      topology,
      IceIds.playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isNavalMissionAccepted(candidate),
  );
}
