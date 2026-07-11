// Compact incremental equivalence expectation shorthands
// (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

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

void iceExpectFamilyOnCorpus({
  required Game game,
  required MapTopology topology,
  required String family,
  required String label,
  required bool Function() fullPass,
  required bool Function(IncrementalCandidateValidator validator) incremental,
  Orders basePrefix = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: IceIds.playerId,
    basePrefix: basePrefix,
    family: family,
    label: label,
    fullPass: fullPass,
    incremental: incremental,
    tileMapByRegion: tileMapByRegion,
  );
}

// dart format off
void iceExpectBuildOnCorpus({required BuildUnitOrder candidate, required String label, Orders basePrefix = const Orders()}) {final game = iceBuildCorpusGame(); const topology = iceBuildCorpusTopology; iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Build', label: label, basePrefix: basePrefix, fullPass: () => fullPassBuildAccepted(game, topology, IceIds.playerId, basePrefix, candidate), incremental: (validator) => validator.isBuildAccepted(candidate));}

void iceExpectWorkOnCorpus({required Game game, required MapTopology topology, required WorkOrder candidate, required String label, Orders basePrefix = const Orders(), Map<String, TileMapResult>? tileMapByRegion}) {iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Work', label: label, basePrefix: basePrefix, tileMapByRegion: tileMapByRegion, fullPass: () => fullPassWorkAccepted(game, topology, IceIds.playerId, basePrefix, candidate, tileMapByRegion: tileMapByRegion), incremental: (validator) => validator.isWorkAccepted(candidate));}

void iceExpectDiplomaticOnCorpus({required Game game, required MapTopology topology, required DiplomaticOrder candidate, required String label, Orders basePrefix = const Orders()}) {iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Diplomatic', label: label, basePrefix: basePrefix, fullPass: () => fullPassDiplomaticAccepted(game, topology, IceIds.playerId, basePrefix, candidate), incremental: (validator) => validator.isDiplomaticAccepted(candidate));}

void iceRunMoveRow({required String unitId, required String destLocal, required String label, Orders basePrefix = const Orders()}) {final game = moveCorpusGame(); final topology = moveCorpusTopology(); final candidate = MoveOrder(unitId: unitId, destinationTileKey: destLocal.isEmpty ? '' : iceTile(destLocal)); iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Move', label: label, basePrefix: basePrefix, fullPass: () => fullPassMoveAccepted(game, topology, IceIds.playerId, basePrefix, candidate), incremental: (validator) => validator.isMoveAccepted(candidate));}

void iceRunArmyMoveRow({required String armyId, required String destLocal, required String label, Orders basePrefix = const Orders()}) {final game = armyCorpusGame(); final topology = armyCorpusTopology(); final candidate = ArmyMoveOrder(armyId: armyId, destinationProvinceId: IceIds.prov(destLocal)); iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Army move', label: label, basePrefix: basePrefix, fullPass: () => fullPassArmyMoveAccepted(game, topology, IceIds.playerId, basePrefix, candidate), incremental: (validator) => validator.isArmyMoveAccepted(candidate));}

void iceRunNavalMoveRow({required String fleetId, required String destSeaZoneId, required String label}) {final game = navalCorpusGame(); final topology = navalCorpusTopology(); final candidate = NavalMoveOrder(fleetId: fleetId, destinationSeaZoneId: destSeaZoneId); iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Naval move', label: label, fullPass: () => fullPassNavalMoveAccepted(game, topology, IceIds.playerId, const Orders(), candidate), incremental: (validator) => validator.isNavalMoveAccepted(candidate));}

void iceRunNavalMissionRow({required String fleetId, required String mission, required String label}) {final game = navalCorpusGame(); final topology = navalCorpusTopology(); final candidate = NavalMissionOrder(fleetId: fleetId, mission: mission); iceExpectFamilyOnCorpus(game: game, topology: topology, family: 'Naval mission', label: label, fullPass: () => fullPassNavalMissionAccepted(game, topology, IceIds.playerId, const Orders(), candidate), incremental: (validator) => validator.isNavalMissionAccepted(candidate));}
// dart format on
