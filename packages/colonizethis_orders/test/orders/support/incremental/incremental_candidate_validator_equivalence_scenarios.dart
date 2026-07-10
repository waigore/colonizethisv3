// Table-driven IncrementalCandidateValidator equivalence scenarios (Refs #3949).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../scenario_runner.dart';
import 'incremental_candidate_validator_equivalence_expectation_shorthand.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

List<RunnableScenario> incrementalCandidateValidatorEquivalenceScenarios() => [
  // dart format off
  RunnableScenario(
    label: 'move: builder onto own province (accepted)',
    run: () => iceRunMoveRow(
      unitId: 'u_builder',
      destLocal: 'P2',
      label: 'builder->own province',
    ),
  ),
  RunnableScenario(
    label: 'move: builder onto other GP province (rejected)',
    run: () => iceRunMoveRow(
      unitId: 'u_builder',
      destLocal: 'P3',
      label: 'builder->other GP province',
    ),
  ),
  RunnableScenario(
    label: 'move: explorer onto Minor province (accepted)',
    run: () => iceRunMoveRow(
      unitId: 'u_explorer',
      destLocal: 'P4',
      label: 'explorer->minor province',
    ),
  ),
  RunnableScenario(
    label: 'move: spy onto other GP province (accepted)',
    run: () => iceRunMoveRow(
      unitId: 'u_spy',
      destLocal: 'P3',
      label: 'spy->other GP province',
    ),
  ),
  RunnableScenario(
    label: 'move: military regiment via MoveOrder (rejected)',
    run: () => iceRunMoveRow(
      unitId: 'u_pikemen',
      destLocal: 'P2',
      label: 'pikemen via MoveOrder',
    ),
  ),
  RunnableScenario(
    label: 'move: missing unit (rejected)',
    run: () => iceRunMoveRow(
      unitId: 'unknown_unit',
      destLocal: 'P2',
      label: 'unknown unit',
    ),
  ),
  RunnableScenario(
    label: 'move: empty destination tile (rejected)',
    run: () => iceRunMoveRow(
      unitId: 'u_builder',
      destLocal: '',
      label: 'empty destination',
    ),
  ),
  RunnableScenario(
    label: 'move: rejected because basePrefix has work order for same unit (move XOR work cascade)',
    run: () => iceRunMoveRow(
      unitId: 'u_explorer',
      destLocal: 'P2',
      label: 'move w/ existing work for same unit',
      basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
    ),
  ),
  RunnableScenario(
    label: 'move: with non-empty accepted basePrefix (accepted)',
    run: () => iceRunMoveRow(
      unitId: 'u_builder',
      destLocal: 'P2',
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
    ),
  ),
  RunnableScenario(
    label: 'build: candidate remains equivalent to full-pass path',
    run: () => iceExpectBuildOnCorpus(
      candidate: iceBuildUnit('pikemen'),
      label: 'single build candidate',
    ),
  ),
  RunnableScenario(
    label: 'build: successive candidate probes stay full-pass equivalent (#2394)',
    run: () => iceExpectSequentialIncrementalMatchesFullPass(
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
    ),
  ),
  RunnableScenario(
    label: 'work: non-empty basePrefix replay remains equivalent',
    run: () => iceExpectWorkOnCorpus(
      game: moveCorpusGame(),
      topology: moveCorpusTopology(),
      candidate: WorkOrder(
        unitId: 'u_explorer',
        target: kWorkTargetExplore,
        targetTileKey: iceTile('P2'),
      ),
      label: 'duplicate work unit with basePrefix',
      basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
    ),
  ),
  RunnableScenario(
    label: 'diplomatic: non-empty basePrefix replay remains equivalent',
    run: () => iceExpectDiplomaticOnCorpus(
      game: moveCorpusGame(),
      topology: moveCorpusTopology(),
      candidate: const DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'p2',
      ),
      label: 'same-target non-economic conflict',
      basePrefix: iceDeclareWarPrefix('p2'),
    ),
  ),
  RunnableScenario(
    label: 'diplomatic: sequential probes on one validator stay equivalent (#2394)',
    run: () => iceExpectSequentialIncrementalMatchesFullPass(
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
    ),
  ),
  RunnableScenario(
    label: 'prefetched DiplomacyFactionMembership matches lazy membership (#2394)',
    run: () => iceExpectPrefetchedArmyMoveEquivalence(
      candidate: const ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: 'oldWorld|P4',
      ),
      game: armyCorpusGame(),
      topology: armyCorpusTopology(),
      playerId: IceIds.playerId,
    ),
  ),
  RunnableScenario(
    label: 'army move: into own adjacent province (accepted)',
    run: () => iceRunArmyMoveRow(
      armyId: 'field_a',
      destLocal: 'P2',
      label: 'own adjacent',
    ),
  ),
  RunnableScenario(
    label: 'army move: into other GP without war (rejected)',
    run: () => iceRunArmyMoveRow(
      armyId: 'field_a',
      destLocal: 'P3',
      label: 'GP no war',
    ),
  ),
  RunnableScenario(
    label: 'army move: into other GP with same-turn declare war (accepted)',
    run: () => iceRunArmyMoveRow(
      armyId: 'field_a',
      destLocal: 'P3',
      label: 'GP with declare war',
      basePrefix: iceDeclareWarPrefix('p2'),
    ),
  ),
  RunnableScenario(
    label: 'army move: into Minor without war (rejected)',
    run: () => iceRunArmyMoveRow(
      armyId: 'field_a',
      destLocal: 'P4',
      label: 'minor no war',
    ),
  ),
  RunnableScenario(
    label: 'army move: missing army (rejected)',
    run: () => iceRunArmyMoveRow(
      armyId: 'unknown_army',
      destLocal: 'P2',
      label: 'unknown army',
    ),
  ),
  RunnableScenario(
    label: 'naval move: at-sea fleet to adjacent sea zone (accepted)',
    run: () => iceRunNavalMoveRow(
      fleetId: 'fleet_atSea',
      destSeaZoneId: 'oldWorld|sea2',
      label: 'sea1->sea2',
    ),
  ),
  RunnableScenario(
    label: 'naval move: at-sea fleet to non-adjacent sea zone (rejected)',
    run: () => iceRunNavalMoveRow(
      fleetId: 'fleet_atSea',
      destSeaZoneId: 'oldWorld|seaZ',
      label: 'sea1->unknown',
    ),
  ),
  RunnableScenario(
    label: 'naval move: in-port fleet undock to adjacent sea zone (accepted)',
    run: () => iceRunNavalMoveRow(
      fleetId: 'fleet_inPort',
      destSeaZoneId: 'oldWorld|sea1',
      label: 'inPort->sea1',
    ),
  ),
  RunnableScenario(
    label: 'naval move: missing fleet (rejected)',
    run: () => iceRunNavalMoveRow(
      fleetId: 'unknown_fleet',
      destSeaZoneId: 'oldWorld|sea1',
      label: 'unknown fleet',
    ),
  ),
  RunnableScenario(
    label: 'naval mission: patrol owned fleet (accepted)',
    run: () => iceRunNavalMissionRow(
      fleetId: 'fleet_atSea',
      mission: 'patrol',
      label: 'patrol owned',
    ),
  ),
  RunnableScenario(
    label: 'naval mission: blockade without target province (rejected)',
    run: () => iceRunNavalMissionRow(
      fleetId: 'fleet_atSea',
      mission: 'blockade',
      label: 'blockade no target',
    ),
  ),
  RunnableScenario(
    label: 'naval mission: missing fleet (rejected)',
    run: () => iceRunNavalMissionRow(
      fleetId: 'unknown_fleet',
      mission: 'patrol',
      label: 'unknown fleet',
    ),
  ),
  // dart format on
];
