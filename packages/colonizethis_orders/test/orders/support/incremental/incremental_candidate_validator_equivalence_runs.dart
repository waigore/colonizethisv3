// IncrementalCandidateValidator equivalence run bodies (Refs #3949 slice 135).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'incremental_candidate_validator_equivalence_expectation_shorthand.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

void iceRunMoveBuilderOwnProvince() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(
        unitId: 'u_builder',
        destinationTileKey: iceTile('P2'),
      ),
      label: 'builder->own province',
    );

void iceRunMoveBuilderOtherGp() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(
        unitId: 'u_builder',
        destinationTileKey: iceTile('P3'),
      ),
      label: 'builder->other GP province',
    );

void iceRunMoveExplorerMinor() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(
        unitId: 'u_explorer',
        destinationTileKey: iceTile('P4'),
      ),
      label: 'explorer->minor province',
    );

void iceRunMoveSpyOtherGp() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(
        unitId: 'u_spy',
        destinationTileKey: iceTile('P3'),
      ),
      label: 'spy->other GP province',
    );

void iceRunMoveMilitaryRegiment() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(
        unitId: 'u_pikemen',
        destinationTileKey: iceTile('P2'),
      ),
      label: 'pikemen via MoveOrder',
    );

void iceRunMoveMissingUnit() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(
        unitId: 'unknown_unit',
        destinationTileKey: iceTile('P2'),
      ),
      label: 'unknown unit',
    );

void iceRunMoveEmptyDestination() => iceExpectMoveOnCorpus(
      candidate: MoveOrder(unitId: 'u_builder', destinationTileKey: ''),
      label: 'empty destination',
    );

void iceRunMoveXorWorkCascade() {
  final tile = iceTile('P2');
  iceExpectMoveOnCorpus(
    candidate: MoveOrder(
      unitId: 'u_explorer',
      destinationTileKey: tile,
    ),
    label: 'move w/ existing work for same unit',
    basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
  );
}

void iceRunMoveNonEmptyBasePrefix() {
  iceExpectMoveOnCorpus(
    candidate: MoveOrder(
      unitId: 'u_builder',
      destinationTileKey: iceTile('P2'),
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
}

void iceRunBuildSingleCandidate() => iceExpectBuildOnCorpus(
      candidate: iceBuildUnit('pikemen'),
      label: 'single build candidate',
    );

void iceRunBuildSuccessiveProbes() =>
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

void iceRunWorkNonEmptyBasePrefix() {
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
}

void iceRunDiplomaticNonEmptyBasePrefix() => iceExpectDiplomaticOnCorpus(
      game: moveCorpusGame(),
      topology: moveCorpusTopology(),
      candidate: const DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'p2',
      ),
      label: 'same-target non-economic conflict',
      basePrefix: iceDeclareWarPrefix('p2'),
    );

void iceRunDiplomaticSequentialProbes() =>
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

void iceRunPrefetchedFactionMembership() => iceExpectPrefetchedArmyMoveEquivalence(
      candidate: const ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: 'oldWorld|P4',
      ),
      game: armyCorpusGame(),
      topology: armyCorpusTopology(),
      playerId: IceIds.playerId,
    );

void iceRunArmyMoveOwnAdjacent() => iceExpectArmyMoveOnCorpus(
      candidate: ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: IceIds.prov('P2'),
      ),
      label: 'own adjacent',
    );

void iceRunArmyMoveGpNoWar() => iceExpectArmyMoveOnCorpus(
      candidate: ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: IceIds.prov('P3'),
      ),
      label: 'GP no war',
    );

void iceRunArmyMoveGpDeclareWar() => iceExpectArmyMoveOnCorpus(
      candidate: ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: IceIds.prov('P3'),
      ),
      label: 'GP with declare war',
      basePrefix: iceDeclareWarPrefix('p2'),
    );

void iceRunArmyMoveMinorNoWar() => iceExpectArmyMoveOnCorpus(
      candidate: ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: IceIds.prov('P4'),
      ),
      label: 'minor no war',
    );

void iceRunArmyMoveMissingArmy() => iceExpectArmyMoveOnCorpus(
      candidate: ArmyMoveOrder(
        armyId: 'unknown_army',
        destinationProvinceId: IceIds.prov('P2'),
      ),
      label: 'unknown army',
    );

void iceRunNavalMoveAdjacentSea() => iceExpectNavalMoveOnCorpus(
      candidate: NavalMoveOrder(
        fleetId: 'fleet_atSea',
        destinationSeaZoneId: 'oldWorld|sea2',
      ),
      label: 'sea1->sea2',
    );

void iceRunNavalMoveNonAdjacentSea() => iceExpectNavalMoveOnCorpus(
      candidate: NavalMoveOrder(
        fleetId: 'fleet_atSea',
        destinationSeaZoneId: 'oldWorld|seaZ',
      ),
      label: 'sea1->unknown',
    );

void iceRunNavalMoveUndock() => iceExpectNavalMoveOnCorpus(
      candidate: NavalMoveOrder(
        fleetId: 'fleet_inPort',
        destinationSeaZoneId: 'oldWorld|sea1',
      ),
      label: 'inPort->sea1',
    );

void iceRunNavalMoveMissingFleet() => iceExpectNavalMoveOnCorpus(
      candidate: NavalMoveOrder(
        fleetId: 'unknown_fleet',
        destinationSeaZoneId: 'oldWorld|sea1',
      ),
      label: 'unknown fleet',
    );

void iceRunNavalMissionPatrol() => iceExpectNavalMissionOnCorpus(
      candidate: NavalMissionOrder(
        fleetId: 'fleet_atSea',
        mission: 'patrol',
      ),
      label: 'patrol owned',
    );

void iceRunNavalMissionBlockadeNoTarget() => iceExpectNavalMissionOnCorpus(
      candidate: NavalMissionOrder(
        fleetId: 'fleet_atSea',
        mission: 'blockade',
      ),
      label: 'blockade no target',
    );

void iceRunNavalMissionMissingFleet() => iceExpectNavalMissionOnCorpus(
      candidate: NavalMissionOrder(
        fleetId: 'unknown_fleet',
        mission: 'patrol',
      ),
      label: 'unknown fleet',
    );
