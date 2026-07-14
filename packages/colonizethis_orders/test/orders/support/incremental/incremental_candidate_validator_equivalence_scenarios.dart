// Table-driven IncrementalCandidateValidator equivalence scenarios (Refs #3949).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../scenario_runner.dart';
import 'incremental_candidate_validator_equivalence_expectation_shorthand.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

List<RunnableScenario> incrementalCandidateValidatorEquivalenceScenarios() => [
  // dart format off
  rs('move: builder onto own province (accepted)', () => iceRunMoveRow(unitId: 'u_builder', destLocal: 'P2', label: 'builder->own province')),
  rs('move: builder onto other GP province (rejected)', () => iceRunMoveRow(unitId: 'u_builder', destLocal: 'P3', label: 'builder->other GP province')),
  rs('move: explorer onto Minor province (accepted)', () => iceRunMoveRow(unitId: 'u_explorer', destLocal: 'P4', label: 'explorer->minor province')),
  rs('move: spy onto other GP province (accepted)', () => iceRunMoveRow(unitId: 'u_spy', destLocal: 'P3', label: 'spy->other GP province')),
  rs('move: military regiment via MoveOrder (rejected)', () => iceRunMoveRow(unitId: 'u_pikemen', destLocal: 'P2', label: 'pikemen via MoveOrder')),
  rs('move: missing unit (rejected)', () => iceRunMoveRow(unitId: 'unknown_unit', destLocal: 'P2', label: 'unknown unit')),
  rs('move: empty destination tile (rejected)', () => iceRunMoveRow(unitId: 'u_builder', destLocal: '', label: 'empty destination')),
  rs('move: rejected because basePrefix has work order for same unit (move XOR work cascade)',() => iceRunMoveRow(unitId: 'u_explorer',destLocal: 'P2',label: 'move w/ existing work for same unit',basePrefix: iceExploreWorkPrefix('u_explorer','P2')),),
  rs('move: with non-empty accepted basePrefix (accepted)',() => iceRunMoveRow(unitId: 'u_builder',destLocal: 'P2',label: 'builder w/ prior explorer move in basePrefix',basePrefix: Orders(moveOrdersByPlayerId: { IceIds.playerId: [MoveOrder(unitId: 'u_explorer',destinationTileKey: iceTile('P2')),],})),),
  rs('build: candidate remains equivalent to full-pass path', () => iceExpectBuildOnCorpus(candidate: iceBuildUnit('pikemen'), label: 'single build candidate')),
  rs('build: successive candidate probes stay full-pass equivalent (#2394)',() => iceExpectSequentialIncrementalMatchesFullPass(game: iceBuildCorpusGame(),topology: iceBuildCorpusTopology,playerId: IceIds.playerId,candidates: [iceBuildUnit('pikemen'),iceBuildUnit('musketeers'),],incremental: (validator,candidate) => validator.isBuildAccepted(candidate),fullPass: (candidate) => fullPassBuildAccepted(iceBuildCorpusGame(),iceBuildCorpusTopology,IceIds.playerId,const Orders(),candidate)),),
  rs('work: non-empty basePrefix replay remains equivalent',() => iceExpectWorkOnCorpus(game: moveCorpusGame(),topology: moveCorpusTopology(),candidate: WorkOrder(unitId: 'u_explorer',target: kWorkTargetExplore,targetTileKey: iceTile('P2')),label: 'duplicate work unit with basePrefix',basePrefix: iceExploreWorkPrefix('u_explorer','P2')),),
  rs('diplomatic: non-empty basePrefix replay remains equivalent',() => iceExpectDiplomaticOnCorpus(game: moveCorpusGame(),topology: moveCorpusTopology(),candidate: const DiplomaticOrder(type: DiplomaticOrderType.alliance,targetFactionId: 'p2'),label: 'same-target non-economic conflict',basePrefix: iceDeclareWarPrefix('p2')),),
  rs('diplomatic: sequential probes on one validator stay equivalent (#2394)',() => iceExpectSequentialIncrementalMatchesFullPass(game: moveCorpusGame(),topology: moveCorpusTopology(),playerId: IceIds.playerId,basePrefix: iceDeclareWarPrefix('p2'),candidates: const [DiplomaticOrder(type: DiplomaticOrderType.alliance,targetFactionId: 'p2'),DiplomaticOrder(type: DiplomaticOrderType.declareWar,targetFactionId: 'p3'),DiplomaticOrder(type: DiplomaticOrderType.alliance,targetFactionId: 'p2'),],incremental: (validator,candidate) => validator.isDiplomaticAccepted(candidate),fullPass: (candidate) => fullPassDiplomaticAccepted(moveCorpusGame(),moveCorpusTopology(),IceIds.playerId,iceDeclareWarPrefix('p2'),candidate)),),
  rs('prefetched DiplomacyFactionMembership matches lazy membership (#2394)',() => iceExpectPrefetchedArmyMoveEquivalence(candidate: const ArmyMoveOrder(armyId: 'field_a',destinationProvinceId: 'oldWorld|P4'),game: armyCorpusGame(),topology: armyCorpusTopology(),playerId: IceIds.playerId),),
  rs('army move: into own adjacent province (accepted)', () => iceRunArmyMoveRow(armyId: 'field_a', destLocal: 'P2', label: 'own adjacent')),
  rs('army move: into other GP without war (rejected)', () => iceRunArmyMoveRow(armyId: 'field_a', destLocal: 'P3', label: 'GP no war')),
  rs('army move: into other GP with same-turn declare war (accepted)', () => iceRunArmyMoveRow(armyId: 'field_a', destLocal: 'P3', label: 'GP with declare war', basePrefix: iceDeclareWarPrefix('p2'))),

  rs('army move: into Minor without war (rejected)', () => iceRunArmyMoveRow(armyId: 'field_a', destLocal: 'P4', label: 'minor no war')),
  rs('army move: missing army (rejected)', () => iceRunArmyMoveRow(armyId: 'unknown_army', destLocal: 'P2', label: 'unknown army')),
  rs('naval move: at-sea fleet to adjacent sea zone (accepted)', () => iceRunNavalMoveRow(fleetId: 'fleet_atSea', destSeaZoneId: 'oldWorld|sea2', label: 'sea1->sea2')),
  rs('naval move: at-sea fleet to non-adjacent sea zone (rejected)', () => iceRunNavalMoveRow(fleetId: 'fleet_atSea', destSeaZoneId: 'oldWorld|seaZ', label: 'sea1->unknown')),
  rs('naval move: in-port fleet undock to adjacent sea zone (accepted)', () => iceRunNavalMoveRow(fleetId: 'fleet_inPort', destSeaZoneId: 'oldWorld|sea1', label: 'inPort->sea1')),
  rs('naval move: missing fleet (rejected)', () => iceRunNavalMoveRow(fleetId: 'unknown_fleet', destSeaZoneId: 'oldWorld|sea1', label: 'unknown fleet')),
  rs('naval mission: patrol owned fleet (accepted)', () => iceRunNavalMissionRow(fleetId: 'fleet_atSea', mission: 'patrol', label: 'patrol owned')),
  rs('naval mission: blockade without target province (rejected)', () => iceRunNavalMissionRow(fleetId: 'fleet_atSea', mission: 'blockade', label: 'blockade no target')),
  rs('naval mission: missing fleet (rejected)', () => iceRunNavalMissionRow(fleetId: 'unknown_fleet', mission: 'patrol', label: 'unknown fleet')),
  // dart format on
];
