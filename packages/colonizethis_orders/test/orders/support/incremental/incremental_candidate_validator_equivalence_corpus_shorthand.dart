import 'package:colonizethis_data/colonizethis_data.dart';
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

String iceTile(String localProv) => '${IceIds.prov(localProv)}|0|0';

void iceExpectMoveTo(
  String unitId,
  String tileKey, {
  required String label,
  Orders basePrefix = const Orders(),
}) {
  iceExpectMoveOnCorpus(
    candidate: MoveOrder(unitId: unitId, destinationTileKey: tileKey),
    label: label,
    basePrefix: basePrefix,
  );
}

void iceExpectArmyMoveTo(
  String armyId,
  String destLocalProv, {
  required String label,
  Orders basePrefix = const Orders(),
}) {
  iceExpectArmyMoveOnCorpus(
    candidate: ArmyMoveOrder(
      armyId: armyId,
      destinationProvinceId: IceIds.prov(destLocalProv),
    ),
    label: label,
    basePrefix: basePrefix,
  );
}

void iceExpectNavalMoveTo(
  String fleetId,
  String destSeaZoneId, {
  required String label,
  Orders basePrefix = const Orders(),
}) {
  iceExpectNavalMoveOnCorpus(
    candidate: NavalMoveOrder(
      fleetId: fleetId,
      destinationSeaZoneId: destSeaZoneId,
    ),
    label: label,
    basePrefix: basePrefix,
  );
}

void iceExpectNavalMissionFor(
  String fleetId,
  String mission, {
  required String label,
  Orders basePrefix = const Orders(),
}) {
  iceExpectNavalMissionOnCorpus(
    candidate: NavalMissionOrder(fleetId: fleetId, mission: mission),
    label: label,
    basePrefix: basePrefix,
  );
}

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
