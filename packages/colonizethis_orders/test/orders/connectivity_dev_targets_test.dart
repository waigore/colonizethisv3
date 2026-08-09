import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_targets.dart';
import 'package:colonizethis_orders/src/orders/feedstock_extraction_targets.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/connectivity_dev_extended_fixtures.dart';
import 'support/suggestion/connectivity_dev_targets_fixtures.dart';
import 'support/suggestion/order_suggestion_work_feedstock_priority_fixtures.dart';

void main() {
  runLabeledScenarioGroup('prioritizeBuildRoadCandidatesByConnectivity', [
    rs('AC-A2 frontier hard demotion', () {
      final snapshot = connectivityDevSnapshot(
        frontier: {'oldWorld|p1|0|1'},
        extensionDistance: {'oldWorld|p1|0|1': 2},
      );
      final ordered = prioritizeBuildRoadCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['oldWorld|p1|9|9', 'oldWorld|p1|0|1'],
      );
      expect(ordered.first, 'oldWorld|p1|0|1');
    }),
    rs('AC-A3 nearest-target-first within frontier', () {
      final snapshot = connectivityDevSnapshot(
        frontier: {'oldWorld|p1|0|1', 'oldWorld|p1|0|3'},
        extensionDistance: {'oldWorld|p1|0|1': 1, 'oldWorld|p1|0|3': 3},
      );
      final ordered = prioritizeBuildRoadCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['oldWorld|p1|0|3', 'oldWorld|p1|0|1'],
      );
      expect(ordered, ['oldWorld|p1|0|1', 'oldWorld|p1|0|3']);
    }),
    rs('AC-A4 baseline when no unconnected targets', () {
      final snapshot = connectivityDevSnapshot(hasTargets: false);
      const input = ['oldWorld|p1|9|9', 'oldWorld|p1|0|1'];
      expect(
        prioritizeBuildRoadCandidatesByConnectivity(
          snapshot: snapshot,
          sortedVisible: input,
        ),
        input,
      );
    }),
  ], runRunnableScenario);

  runLabeledScenarioGroup('prioritizeBuildImprovementCandidatesByConnectivity', [
    rs('AC-C1 connected > adjacent > far', () {
      final snapshot = connectivityDevSnapshot(
        connected: {'c'},
        adjacent: {'a'},
      );
      final ordered = prioritizeBuildImprovementCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['f', 'a', 'c'],
      );
      expect(ordered, ['c', 'a', 'f']);
    }),
  ], runRunnableScenario);

  runLabeledScenarioGroup(
    'applyBuildImprovementConnectivityPreservingFeedstock',
    [
      rs('AC-C3 feedstock tile precedes connected non-feedstock tile', () {
        final game = feedstockPriorityGame();
        expect(
          feedstockExtractionResourceIdsForPlayer(
            game,
            feedstockPrioritySupplierId,
          ),
          contains('iron'),
        );
        final snapshot = connectivityDevSnapshot(
          connected: {feedstockPrioritySupplierGrainTile},
        );
        final ordered = applyBuildImprovementConnectivityPreservingFeedstock(
          game: game,
          playerId: feedstockPrioritySupplierId,
          sortedVisible: [
            feedstockPrioritySupplierGrainTile,
            feedstockPrioritySupplierIronTile,
          ],
          snapshot: snapshot,
        );
        expect(ordered.first, feedstockPrioritySupplierIronTile);
      }),
    ],
    runRunnableScenario,
  );

  runLabeledScenarioGroup('prioritizeBuildRailCandidatesByConnectivity', [
    rs('AC-B1 bottleneck promotion', () {
      final snapshot = connectivityDevSnapshot(
        connected: {'bottleneck', 'plain'},
        bottleneck: {'bottleneck'},
      );
      final ordered = prioritizeBuildRailCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['plain', 'bottleneck'],
      );
      expect(ordered.first, 'bottleneck');
    }),
    rs('AC-B2 no-yield-gain demotion', () {
      final snapshot = connectivityDevSnapshot(
        connected: {'bottleneck', 'satisfied'},
        bottleneck: {'bottleneck'},
      );
      final ordered = prioritizeBuildRailCandidatesByConnectivity(
        snapshot: snapshot,
        sortedVisible: ['satisfied', 'bottleneck'],
      );
      expect(ordered.first, 'bottleneck');
    }),
  ], runRunnableScenario);

  runLabeledScenarioGroup('prioritizeBuildPortCandidatesByConnectivity', [
    rs('AC-D1 overseas resource province promotion', () {
      final c = connectivityDevOverseasResourcePortCase();
      expect(
        prioritizeBuildPortCandidatesByConnectivity(
          snapshot: c.snapshot,
          sortedVisible: c.visible,
          game: c.game,
          topology: c.topology,
        ).first,
        c.expectedFirst,
      );
    }),
    rs('AC-D2 sea-unreachable demotion', () {
      final c = connectivityDevSeaUnreachablePortCase();
      expect(
        prioritizeBuildPortCandidatesByConnectivity(
          snapshot: c.snapshot,
          sortedVisible: c.visible,
          game: c.game,
          topology: c.topology,
        ).first,
        c.expectedFirst,
      );
    }),
  ], runRunnableScenario);

  runLabeledScenarioGroup('stablePartitionByConnectivityTier', [
    rs('preserves relative order within tier', () {
      final ordered = stablePartitionByConnectivityTier(
        ['b2', 'a2', 'b1', 'a1'],
        (k) => k.endsWith('1') ? 0 : 1,
      );
      expect(ordered, ['b1', 'a1', 'b2', 'a2']);
    }),
  ], runRunnableScenario);

  runLabeledScenarioGroup('applyConnectivityDevTargetOrdering', [
    rs('unknown target unchanged', () {
      const input = ['t1', 't2'];
      expect(
        applyConnectivityDevTargetOrdering(
          workTarget: kWorkTargetExplore,
          sortedVisible: input,
          snapshot: connectivityDevSnapshot(),
          game: connectivityDevEmptyGame(),
          topology: const MapTopology(nodes: [], edges: []),
          tileMapByRegion: const {},
        ),
        input,
      );
    }),
  ], runRunnableScenario);

  runLabeledScenarioGroup('buildConnectivityDevSnapshot', [
    rs('AC-A5 owned-land traversal only for extension distances', connectivityDevRunForeignBarrierSnapshot),
  ], runRunnableScenario);

  runLabeledScenarioGroup('build_road connectivity ordering with probe cap', [
    rs('AC-A7 frontier tile is first accepted despite lex-smaller non-frontier', connectivityDevRunFrontierRoadLexOrder),
  ], runRunnableScenario);

  runLabeledScenarioGroup('Town-rule awareness (AC-F7)', [
    rs('town-connected resource tile is not a frontier extension target', connectivityDevRunTownRuleFrontier),
  ], runRunnableScenario);

  runLabeledScenarioGroup('suggestWorkOrders connectivity parity (AC-F6)', [
    rs('suggestWorkOrders applies connectivity ordering for build_improvement', connectivityDevRunSuggestionParity),
  ], runRunnableScenario);

  runLabeledScenarioGroup('suggestWorkOrders determinism (AC-F4)', [
    rs('byte-identical across two passes', connectivityDevRunWorkOrdersDeterminism),
  ], runRunnableScenario);
}
