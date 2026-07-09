// Compact IncrementalCandidateValidator equivalence assertions (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
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
      iceExpectMoveTo('u_builder', iceTile('P2'), label: 'builder->own province');
    case IncrementalEquivalenceTarget.moveBuilderOtherGp:
      iceExpectMoveTo('u_builder', iceTile('P3'), label: 'builder->other GP province');
    case IncrementalEquivalenceTarget.moveExplorerMinor:
      iceExpectMoveTo('u_explorer', iceTile('P4'), label: 'explorer->minor province');
    case IncrementalEquivalenceTarget.moveSpyOtherGp:
      iceExpectMoveTo('u_spy', iceTile('P3'), label: 'spy->other GP province');
    case IncrementalEquivalenceTarget.moveMilitaryRegiment:
      iceExpectMoveTo('u_pikemen', iceTile('P2'), label: 'pikemen via MoveOrder');
    case IncrementalEquivalenceTarget.moveMissingUnit:
      iceExpectMoveTo('unknown_unit', iceTile('P2'), label: 'unknown unit');
    case IncrementalEquivalenceTarget.moveEmptyDestination:
      iceExpectMoveTo('u_builder', '', label: 'empty destination');
    case IncrementalEquivalenceTarget.moveXorWorkCascade:
        final tile = iceTile('P2');
        iceExpectMoveTo(
          'u_explorer',
          tile,
          label: 'move w/ existing work for same unit',
          basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
        );
    case IncrementalEquivalenceTarget.moveNonEmptyBasePrefix:
        final tile = iceTile('P2');
        iceExpectMoveTo(
          'u_builder',
          tile,
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
        expectBuildEquivalent(
          game: iceBuildCorpusGame(),
          topology: iceBuildCorpusTopology,
          playerId: IceIds.playerId,
          basePrefix: const Orders(),
          candidate: iceBuildUnit('pikemen'),
          label: 'single build candidate',
        );
    case IncrementalEquivalenceTarget.buildSuccessiveProbes:
      {
        final game = iceBuildCorpusGame();
        const topology = iceBuildCorpusTopology;
        const basePrefix = Orders();
        final incremental = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: IceIds.playerId,
          basePrefix: basePrefix,
        );
        for (final candidate in [
          iceBuildUnit('pikemen'),
          iceBuildUnit('musketeers'),
        ]) {
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
    case IncrementalEquivalenceTarget.workNonEmptyBasePrefix:
        final tile = iceTile('P2');
        expectWorkEquivalent(
          game: moveCorpusGame(),
          topology: moveCorpusTopology(),
          playerId: IceIds.playerId,
          basePrefix: iceExploreWorkPrefix('u_explorer', 'P2'),
          candidate: WorkOrder(
            unitId: 'u_explorer',
            target: kWorkTargetExplore,
            targetTileKey: tile,
          ),
          label: 'duplicate work unit with basePrefix',
        );
    case IncrementalEquivalenceTarget.diplomaticNonEmptyBasePrefix:
        expectDiplomaticEquivalent(
          game: moveCorpusGame(),
          topology: moveCorpusTopology(),
          playerId: IceIds.playerId,
          basePrefix: iceDeclareWarPrefix('p2'),
          candidate: const DiplomaticOrder(
            type: DiplomaticOrderType.alliance,
            targetFactionId: 'p2',
          ),
          label: 'same-target non-economic conflict',
        );
    case IncrementalEquivalenceTarget.diplomaticSequentialProbes:
      {
        final game = moveCorpusGame();
        final topology = moveCorpusTopology();
        final basePrefix = iceDeclareWarPrefix('p2');
        final incremental = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: IceIds.playerId,
          basePrefix: basePrefix,
        );
        for (final candidate in [
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
        ]) {
          expect(
            incremental.isDiplomaticAccepted(candidate),
            fullPassDiplomaticAccepted(
              game,
              topology,
              IceIds.playerId,
              basePrefix,
              candidate,
            ),
          );
        }
      }
    case IncrementalEquivalenceTarget.prefetchedFactionMembership:
      {
        const candidate = ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P4',
        );
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
    case IncrementalEquivalenceTarget.armyMoveOwnAdjacent:
      iceExpectArmyMoveTo('field_a', 'P2', label: 'own adjacent');
    case IncrementalEquivalenceTarget.armyMoveGpNoWar:
      iceExpectArmyMoveTo('field_a', 'P3', label: 'GP no war');
    case IncrementalEquivalenceTarget.armyMoveGpDeclareWar:
      iceExpectArmyMoveTo(
        'field_a',
        'P3',
        label: 'GP with declare war',
        basePrefix: iceDeclareWarPrefix('p2'),
      );
    case IncrementalEquivalenceTarget.armyMoveMinorNoWar:
      iceExpectArmyMoveTo('field_a', 'P4', label: 'minor no war');
    case IncrementalEquivalenceTarget.armyMoveMissingArmy:
      iceExpectArmyMoveTo('unknown_army', 'P2', label: 'unknown army');
    case IncrementalEquivalenceTarget.navalMoveAdjacentSea:
      iceExpectNavalMoveTo(
        'fleet_atSea',
        'oldWorld|sea2',
        label: 'sea1->sea2',
      );
    case IncrementalEquivalenceTarget.navalMoveNonAdjacentSea:
      iceExpectNavalMoveTo(
        'fleet_atSea',
        'oldWorld|seaZ',
        label: 'sea1->unknown',
      );
    case IncrementalEquivalenceTarget.navalMoveUndock:
      iceExpectNavalMoveTo(
        'fleet_inPort',
        'oldWorld|sea1',
        label: 'inPort->sea1',
      );
    case IncrementalEquivalenceTarget.navalMoveMissingFleet:
      iceExpectNavalMoveTo(
        'unknown_fleet',
        'oldWorld|sea1',
        label: 'unknown fleet',
      );
    case IncrementalEquivalenceTarget.navalMissionPatrol:
      iceExpectNavalMissionFor('fleet_atSea', 'patrol', label: 'patrol owned');
    case IncrementalEquivalenceTarget.navalMissionBlockadeNoTarget:
      iceExpectNavalMissionFor(
        'fleet_atSea',
        'blockade',
        label: 'blockade no target',
      );
    case IncrementalEquivalenceTarget.navalMissionMissingFleet:
      iceExpectNavalMissionFor(
        'unknown_fleet',
        'patrol',
        label: 'unknown fleet',
      );
  }
}
