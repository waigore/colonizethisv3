import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'incremental_candidate_validator_equivalence_naval_helpers.dart';
import 'incremental_candidate_validator_equivalence_test_helpers.dart';

void main() {
  suppressLogsForTests();

  group(
    'IncrementalCandidateValidator equivalence (army/naval) (Refs #2237)',
    () {
      test('army move: into own adjacent province (accepted)', () {
        final game = armyCorpusGame();
        final topology = armyCorpusTopology();
        expectArmyMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: ArmyMoveOrder(
            armyId: 'field_a',
            destinationProvinceId: 'oldWorld|P2',
          ),
          label: 'own adjacent',
        );
      });

      test('army move: into other GP without war (rejected)', () {
        final game = armyCorpusGame();
        final topology = armyCorpusTopology();
        expectArmyMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: ArmyMoveOrder(
            armyId: 'field_a',
            destinationProvinceId: 'oldWorld|P3',
          ),
          label: 'GP no war',
        );
      });

      test(
        'army move: into other GP with same-turn declare war (accepted)',
        () {
          final game = armyCorpusGame();
          final topology = armyCorpusTopology();
          final basePrefix = Orders(
            diplomaticOrdersByPlayerId: {
              'p1': [
                const DiplomaticOrder(
                  type: DiplomaticOrderType.declareWar,
                  targetFactionId: 'p2',
                ),
              ],
            },
          );
          expectArmyMoveEquivalent(
            game: game,
            topology: topology,
            playerId: 'p1',
            basePrefix: basePrefix,
            candidate: ArmyMoveOrder(
              armyId: 'field_a',
              destinationProvinceId: 'oldWorld|P3',
            ),
            label: 'GP with declare war',
          );
        },
      );

      test('army move: into Minor without war (rejected)', () {
        final game = armyCorpusGame();
        final topology = armyCorpusTopology();
        expectArmyMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: ArmyMoveOrder(
            armyId: 'field_a',
            destinationProvinceId: 'oldWorld|P4',
          ),
          label: 'minor no war',
        );
      });

      test('army move: missing army (rejected)', () {
        final game = armyCorpusGame();
        final topology = armyCorpusTopology();
        expectArmyMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: ArmyMoveOrder(
            armyId: 'unknown_army',
            destinationProvinceId: 'oldWorld|P2',
          ),
          label: 'unknown army',
        );
      });

      test('naval move: at-sea fleet to adjacent sea zone (accepted)', () {
        final game = navalCorpusGame();
        final topology = navalCorpusTopology();
        expectNavalMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: const NavalMoveOrder(
            fleetId: 'fleet_atSea',
            destinationSeaZoneId: 'oldWorld|sea2',
          ),
          label: 'sea1->sea2',
        );
      });

      test('naval move: at-sea fleet to non-adjacent sea zone (rejected)', () {
        final game = navalCorpusGame();
        final topology = navalCorpusTopology();
        expectNavalMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: const NavalMoveOrder(
            fleetId: 'fleet_atSea',
            destinationSeaZoneId: 'oldWorld|seaZ',
          ),
          label: 'sea1->unknown',
        );
      });

      test(
        'naval move: in-port fleet undock to adjacent sea zone (accepted)',
        () {
          final game = navalCorpusGame();
          final topology = navalCorpusTopology();
          expectNavalMoveEquivalent(
            game: game,
            topology: topology,
            playerId: 'p1',
            basePrefix: const Orders(),
            candidate: const NavalMoveOrder(
              fleetId: 'fleet_inPort',
              destinationSeaZoneId: 'oldWorld|sea1',
            ),
            label: 'inPort->sea1',
          );
        },
      );

      test('naval move: missing fleet (rejected)', () {
        final game = navalCorpusGame();
        final topology = navalCorpusTopology();
        expectNavalMoveEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: const NavalMoveOrder(
            fleetId: 'unknown_fleet',
            destinationSeaZoneId: 'oldWorld|sea1',
          ),
          label: 'unknown fleet',
        );
      });

      test('naval mission: patrol owned fleet (accepted)', () {
        final game = navalCorpusGame();
        final topology = navalCorpusTopology();
        expectNavalMissionEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: const NavalMissionOrder(
            fleetId: 'fleet_atSea',
            mission: 'patrol',
          ),
          label: 'patrol owned',
        );
      });

      test('naval mission: blockade without target province (rejected)', () {
        final game = navalCorpusGame();
        final topology = navalCorpusTopology();
        expectNavalMissionEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: const NavalMissionOrder(
            fleetId: 'fleet_atSea',
            mission: 'blockade',
          ),
          label: 'blockade no target',
        );
      });

      test('naval mission: missing fleet (rejected)', () {
        final game = navalCorpusGame();
        final topology = navalCorpusTopology();
        expectNavalMissionEquivalent(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: const Orders(),
          candidate: const NavalMissionOrder(
            fleetId: 'unknown_fleet',
            mission: 'patrol',
          ),
          label: 'unknown fleet',
        );
      });
    },
  );
}
