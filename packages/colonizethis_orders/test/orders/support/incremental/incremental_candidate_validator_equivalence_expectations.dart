// Compact IncrementalCandidateValidator equivalence assertions (Refs #3949).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';
import 'incremental_candidate_validator_equivalence_expectation_shorthand.dart';

/// Pins for [incrementalCandidateValidatorEquivalenceScenarios] rows.
enum IncrementalEquivalenceTarget {
  moveBuilderOwnProvince,
  moveBuilderOtherGp,
  moveExplorerMinor,
  moveSpyOtherGp,
  moveMilitaryRegiment,
  moveMissingUnit,
  moveEmptyDestination,
  moveXorWorkCascade,
  moveNonEmptyBasePrefix,
  buildSingleCandidate,
  buildSuccessiveProbes,
  workNonEmptyBasePrefix,
  diplomaticNonEmptyBasePrefix,
  diplomaticSequentialProbes,
  prefetchedFactionMembership,
  armyMoveOwnAdjacent,
  armyMoveGpNoWar,
  armyMoveGpDeclareWar,
  armyMoveMinorNoWar,
  armyMoveMissingArmy,
  navalMoveAdjacentSea,
  navalMoveNonAdjacentSea,
  navalMoveUndock,
  navalMoveMissingFleet,
  navalMissionPatrol,
  navalMissionBlockadeNoTarget,
  navalMissionMissingFleet,
}

void runIncrementalEquivalenceExpectation(IncrementalEquivalenceTarget target) {
  switch (target) {
    case IncrementalEquivalenceTarget.moveBuilderOwnProvince:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: iceTile('P2'),
        ),
        label: 'builder->own province',
      );
    case IncrementalEquivalenceTarget.moveBuilderOtherGp:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: iceTile('P3'),
        ),
        label: 'builder->other GP province',
      );
    case IncrementalEquivalenceTarget.moveExplorerMinor:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: iceTile('P4'),
        ),
        label: 'explorer->minor province',
      );
    case IncrementalEquivalenceTarget.moveSpyOtherGp:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(
          unitId: 'u_spy',
          destinationTileKey: iceTile('P3'),
        ),
        label: 'spy->other GP province',
      );
    case IncrementalEquivalenceTarget.moveMilitaryRegiment:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(
          unitId: 'u_pikemen',
          destinationTileKey: iceTile('P2'),
        ),
        label: 'pikemen via MoveOrder',
      );
    case IncrementalEquivalenceTarget.moveMissingUnit:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(
          unitId: 'unknown_unit',
          destinationTileKey: iceTile('P2'),
        ),
        label: 'unknown unit',
      );
    case IncrementalEquivalenceTarget.moveEmptyDestination:
      iceExpectMoveOnCorpus(
        candidate: MoveOrder(unitId: 'u_builder', destinationTileKey: ''),
        label: 'empty destination',
      );
    case IncrementalEquivalenceTarget.moveXorWorkCascade:
        final tile = iceTile('P2');
        iceExpectMoveOnCorpus(
          candidate: MoveOrder(
            unitId: 'u_explorer',
            destinationTileKey: tile,
          ),
          label: 'move w/ existing work for same unit',
          basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
        );
    case IncrementalEquivalenceTarget.moveNonEmptyBasePrefix:
        final tile = iceTile('P2');
        iceExpectMoveOnCorpus(
          candidate: MoveOrder(
            unitId: 'u_builder',
            destinationTileKey: tile,
          ),
          label: 'builder w/ prior explorer move in basePrefix',
          basePrefix: Orders(
            moveOrdersByPlayerId: {
              IceIds.playerId: [
                MoveOrder(
                  unitId: 'u_explorer',
                  destinationTileKey: iceTile('P2'),
                ),
              ],
            },
          ),
        );
    case IncrementalEquivalenceTarget.buildSingleCandidate:
        iceExpectBuildOnCorpus(
          candidate: iceBuildUnit('pikemen'),
          label: 'single build candidate',
        );
    case IncrementalEquivalenceTarget.buildSuccessiveProbes:
      iceExpectSequentialIncrementalMatchesFullPass(
        game: iceBuildCorpusGame(),
        topology: iceBuildCorpusTopology,
        playerId: IceIds.playerId,
        candidates: [
          iceBuildUnit('pikemen'),
          iceBuildUnit('musketeers'),
        ],
        incremental: (validator, candidate) =>
            validator.isBuildAccepted(candidate),
        fullPass: (candidate) => fullPassBuildAccepted(
          iceBuildCorpusGame(),
          iceBuildCorpusTopology,
          IceIds.playerId,
          const Orders(),
          candidate,
        ),
      );
    case IncrementalEquivalenceTarget.workNonEmptyBasePrefix:
        final tile = iceTile('P2');
        iceExpectWorkOnCorpus(
          game: moveCorpusGame(),
          topology: moveCorpusTopology(),
          candidate: WorkOrder(
            unitId: 'u_explorer',
            target: kWorkTargetExplore,
            targetTileKey: tile,
          ),
          label: 'duplicate work unit with basePrefix',
          basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
        );
    case IncrementalEquivalenceTarget.diplomaticNonEmptyBasePrefix:
        iceExpectDiplomaticOnCorpus(
          game: moveCorpusGame(),
          topology: moveCorpusTopology(),
          candidate: const DiplomaticOrder(
            type: DiplomaticOrderType.alliance,
            targetFactionId: 'p2',
          ),
          label: 'same-target non-economic conflict',
          basePrefix: iceDeclareWarPrefix('p2'),
        );
    case IncrementalEquivalenceTarget.diplomaticSequentialProbes:
      iceExpectSequentialIncrementalMatchesFullPass(
        game: moveCorpusGame(),
        topology: moveCorpusTopology(),
        playerId: IceIds.playerId,
        basePrefix: iceDeclareWarPrefix('p2'),
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.alliance,
            targetFactionId: 'p2',
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'p3',
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.alliance,
            targetFactionId: 'p2',
          ),
        ],
        incremental: (validator, candidate) =>
            validator.isDiplomaticAccepted(candidate),
        fullPass: (candidate) => fullPassDiplomaticAccepted(
          moveCorpusGame(),
          moveCorpusTopology(),
          IceIds.playerId,
          iceDeclareWarPrefix('p2'),
          candidate,
        ),
      );
    case IncrementalEquivalenceTarget.prefetchedFactionMembership:
      iceExpectPrefetchedArmyMoveEquivalence(
        candidate: const ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P4',
        ),
        game: armyCorpusGame(),
        topology: armyCorpusTopology(),
        playerId: IceIds.playerId,
      );
    case IncrementalEquivalenceTarget.armyMoveOwnAdjacent:
      iceExpectArmyMoveOnCorpus(
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: IceIds.prov('P2'),
        ),
        label: 'own adjacent',
      );
    case IncrementalEquivalenceTarget.armyMoveGpNoWar:
      iceExpectArmyMoveOnCorpus(
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: IceIds.prov('P3'),
        ),
        label: 'GP no war',
      );
    case IncrementalEquivalenceTarget.armyMoveGpDeclareWar:
      iceExpectArmyMoveOnCorpus(
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: IceIds.prov('P3'),
        ),
        label: 'GP with declare war',
        basePrefix: iceDeclareWarPrefix('p2'),
      );
    case IncrementalEquivalenceTarget.armyMoveMinorNoWar:
      iceExpectArmyMoveOnCorpus(
        candidate: ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: IceIds.prov('P4'),
        ),
        label: 'minor no war',
      );
    case IncrementalEquivalenceTarget.armyMoveMissingArmy:
      iceExpectArmyMoveOnCorpus(
        candidate: ArmyMoveOrder(
          armyId: 'unknown_army',
          destinationProvinceId: IceIds.prov('P2'),
        ),
        label: 'unknown army',
      );
    case IncrementalEquivalenceTarget.navalMoveAdjacentSea:
      iceExpectNavalMoveOnCorpus(
        candidate: NavalMoveOrder(
          fleetId: 'fleet_atSea',
          destinationSeaZoneId: 'oldWorld|sea2',
        ),
        label: 'sea1->sea2',
      );
    case IncrementalEquivalenceTarget.navalMoveNonAdjacentSea:
      iceExpectNavalMoveOnCorpus(
        candidate: NavalMoveOrder(
          fleetId: 'fleet_atSea',
          destinationSeaZoneId: 'oldWorld|seaZ',
        ),
        label: 'sea1->unknown',
      );
    case IncrementalEquivalenceTarget.navalMoveUndock:
      iceExpectNavalMoveOnCorpus(
        candidate: NavalMoveOrder(
          fleetId: 'fleet_inPort',
          destinationSeaZoneId: 'oldWorld|sea1',
        ),
        label: 'inPort->sea1',
      );
    case IncrementalEquivalenceTarget.navalMoveMissingFleet:
      iceExpectNavalMoveOnCorpus(
        candidate: NavalMoveOrder(
          fleetId: 'unknown_fleet',
          destinationSeaZoneId: 'oldWorld|sea1',
        ),
        label: 'unknown fleet',
      );
    case IncrementalEquivalenceTarget.navalMissionPatrol:
      iceExpectNavalMissionOnCorpus(
        candidate: NavalMissionOrder(
          fleetId: 'fleet_atSea',
          mission: 'patrol',
        ),
        label: 'patrol owned',
      );
    case IncrementalEquivalenceTarget.navalMissionBlockadeNoTarget:
      iceExpectNavalMissionOnCorpus(
        candidate: NavalMissionOrder(
          fleetId: 'fleet_atSea',
          mission: 'blockade',
        ),
        label: 'blockade no target',
      );
    case IncrementalEquivalenceTarget.navalMissionMissingFleet:
      iceExpectNavalMissionOnCorpus(
        candidate: NavalMissionOrder(
          fleetId: 'unknown_fleet',
          mission: 'patrol',
        ),
        label: 'unknown fleet',
      );
  }
}
