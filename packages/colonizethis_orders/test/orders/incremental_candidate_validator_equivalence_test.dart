import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import 'incremental_candidate_validator_equivalence_test_helpers.dart';

void main() {
  suppressLogsForTests();

  group('IncrementalCandidateValidator equivalence (Refs #2237)', () {
    test('move: builder onto own province (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'builder->own province',
      );
    });

    test('move: builder onto other GP province (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: 'oldWorld|P3|0|0',
        ),
        label: 'builder->other GP province',
      );
    });

    test('move: explorer onto Minor province (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: 'oldWorld|P4|0|0',
        ),
        label: 'explorer->minor province',
      );
    });

    test('move: spy onto other GP province (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_spy',
          destinationTileKey: 'oldWorld|P3|0|0',
        ),
        label: 'spy->other GP province',
      );
    });

    test('move: military regiment via MoveOrder (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'u_pikemen',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'pikemen via MoveOrder',
      );
    });

    test('move: missing unit (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(
          unitId: 'unknown_unit',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'unknown unit',
      );
    });

    test('move: empty destination tile (rejected)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const MoveOrder(unitId: 'u_builder', destinationTileKey: ''),
        label: 'empty destination',
      );
    });

    test('move: rejected because basePrefix has work order for same unit '
        '(move XOR work cascade)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      // basePrefix has a work order for u_explorer; adding a move for the
      // same unit invalidates that work via the XOR rule. Full-pass returns
      // false (cascade); incremental must also return false.
      final basePrefix = Orders(
        workOrdersByPlayerId: {
          'p1': [
            const WorkOrder(
              unitId: 'u_explorer',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|P2|0|0',
            ),
          ],
        },
      );
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: const MoveOrder(
          unitId: 'u_explorer',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'move w/ existing work for same unit',
      );
    });

    test('move: with non-empty accepted basePrefix (accepted)', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      // basePrefix already contains an accepted move for explorer; candidate is
      // for builder (independent) and should still be accepted.
      final basePrefix = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            const MoveOrder(
              unitId: 'u_explorer',
              destinationTileKey: 'oldWorld|P2|0|0',
            ),
          ],
        },
      );
      expectMoveEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: const MoveOrder(
          unitId: 'u_builder',
          destinationTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'builder w/ prior explorer move in basePrefix',
      );
    });

    test('build: candidate remains equivalent to full-pass path', () {
      final game = TestFixtures.gameWithSingleOwnedProvince(
        ownerPlayerId: 'p1',
        provinceId: 'oldWorld|p1',
        treasury: 999,
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      expectBuildEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
        candidate: const BuildUnitOrder(
          unitType: 'pikemen',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        ),
        label: 'single build candidate',
      );
    });

    test(
      'build: successive candidate probes stay full-pass equivalent (#2394)',
      () {
        final game = TestFixtures.gameWithSingleOwnedProvince(
          ownerPlayerId: 'p1',
          provinceId: 'oldWorld|p1',
          treasury: 999,
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        const basePrefix = Orders();

        const candidateA = BuildUnitOrder(
          unitType: 'pikemen',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        const candidateB = BuildUnitOrder(
          unitType: 'musketeers',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );

        final incremental = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: basePrefix,
        );
        expect(
          incremental.isBuildAccepted(candidateA),
          fullPassBuildAccepted(game, topology, 'p1', basePrefix, candidateA),
        );
        expect(
          incremental.isBuildAccepted(candidateB),
          fullPassBuildAccepted(game, topology, 'p1', basePrefix, candidateB),
        );
      },
    );

    test('work: non-empty basePrefix replay remains equivalent', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
      final basePrefix = Orders(
        workOrdersByPlayerId: {
          'p1': [
            const WorkOrder(
              unitId: 'u_explorer',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|P2|0|0',
            ),
          ],
        },
      );
      expectWorkEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: const WorkOrder(
          unitId: 'u_explorer',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P2|0|0',
        ),
        label: 'duplicate work unit with basePrefix',
      );
    });

    test('diplomatic: non-empty basePrefix replay remains equivalent', () {
      final game = moveCorpusGame();
      final topology = moveCorpusTopology();
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
      expectDiplomaticEquivalent(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
        candidate: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'p2',
        ),
        label: 'same-target non-economic conflict',
      );
    });

    test(
      'diplomatic: sequential probes on one validator stay equivalent (#2394)',
      () {
        final game = moveCorpusGame();
        final topology = moveCorpusTopology();
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
        const candidateA = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'p2',
        );
        const candidateB = DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'p3',
        );
        final incremental = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: 'p1',
          basePrefix: basePrefix,
        );
        expect(
          incremental.isDiplomaticAccepted(candidateA),
          fullPassDiplomaticAccepted(game, topology, 'p1', basePrefix, candidateA),
        );
        expect(
          incremental.isDiplomaticAccepted(candidateB),
          fullPassDiplomaticAccepted(game, topology, 'p1', basePrefix, candidateB),
        );
        expect(
          incremental.isDiplomaticAccepted(candidateA),
          fullPassDiplomaticAccepted(game, topology, 'p1', basePrefix, candidateA),
        );
      },
    );

    test(
      'prefetched DiplomacyFactionMembership matches lazy membership (#2394)',
      () {
        final game = armyCorpusGame();
        final topology = armyCorpusTopology();
        const playerId = 'p1';
        const basePrefix = Orders();
        final prefetched = DiplomacyFactionMembership.from(game);
        final baseline = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: playerId,
          basePrefix: basePrefix,
        );
        final withPrefetched = IncrementalCandidateValidator.forPlayer(
          game: game,
          topology: topology,
          playerId: playerId,
          basePrefix: basePrefix,
          factionMembership: prefetched,
        );
        const armyMove = ArmyMoveOrder(
          armyId: 'field_a',
          destinationProvinceId: 'oldWorld|P4',
        );
        expect(
          withPrefetched.isArmyMoveAccepted(armyMove),
          baseline.isArmyMoveAccepted(armyMove),
        );
      },
    );
  });
}
