// Table-driven full-candidate snapshot scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_full_candidate_snapshot_fixtures.dart';

void osfcsRunStableSnapshot() {
  final game = fullCandidateSnapshotGame();
  final view = buildPlayerView(
    game,
    fullCandidateSnapshotTopology,
    fullCandidateSnapshotPlayerId,
  );

  final suggestionsFirst = suggestWorkOrders(
    view,
    game,
    fullCandidateSnapshotTopology,
    const Orders(),
  );
  final suggestionsSecond = suggestWorkOrders(
    view,
    game,
    fullCandidateSnapshotTopology,
    const Orders(),
  );

  final snapshotRows = [
    for (final order in suggestionsFirst)
      '${order.unitId}|${order.target}|${order.targetTileKey}',
  ];

  expect(
    snapshotRows,
    const [
      'explorer_1|explore|oldWorld|p_home|0|0',
      'explorer_1|explore|oldWorld|p_target|0|0',
      'explorer_1|prospect|oldWorld|p_home|0|0',
      'explorer_1|prospect|oldWorld|p_target|0|0',
    ],
    reason:
        'Broad suggestWorkOrders full-candidate semantics must remain stable '
        'for deterministic explorer fixtures.',
  );
  expect(
    suggestionsSecond,
    suggestionsFirst,
    reason: 'Repeated invocations should keep deterministic order and content.',
  );
}

List<RunnableScenario>
orderSuggestionFullCandidateSnapshotScenarios() => const [
  rs('suggestWorkOrders full-candidate snapshot remains stable (Refs #2133 AC8)', osfcsRunStableSnapshot),
];
