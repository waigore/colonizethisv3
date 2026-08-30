// Shared fixtures + branch groups for e2eExploreAssignEnabledFromCivilianSnapshot
// (Refs #4598 Slice C densify).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore, kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'explore_assign_snapshot_true_guards_group.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

WorldState _world() => const WorldState(
  turnState: _orderingTurn,
  oldWorld: RegionData(),
  newWorld: RegionData(),
);

Game _game() => Game(
  id: 'g1',
  worldState: _world(),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot _snapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

void registerExploreAssignSnapshotTrueAndGuardGroups() {
  group('e2eExploreAssignEnabledFromCivilianSnapshot — true branches', () {
    test('single unit row with only explore returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'Single Explorer with only Explore available is the canonical '
            'short-circuit case — the slow-path Assign sweep would find '
            'the same affordance enabled.',
      );
    });

    test(
      'single unit row with explore among multiple targets returns true',
      () {
        expect(
          e2eExploreAssignEnabledFromCivilianSnapshot(
            _snapshot(
              availableWorkTargets: const {
                'explorer-1': [
                  kWorkTargetProspect,
                  kWorkTargetExplore,
                  kWorkTargetBuildRoad,
                ],
              },
            ),
          ),
          isTrue,
          reason:
              'Membership uses `List.contains`, so any list containing '
              '`explore` qualifies regardless of position. Order should '
              'not affect the verdict.',
        );
      },
    );

    test('multiple unit rows with explore in only one returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
              'unit-2': [kWorkTargetProspect],
              'explorer-3': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'A single Explore-enabled unit row among non-Explore peers '
            'is sufficient — the panel only needs one assign affordance '
            'to satisfy the bundled-Explore readiness gate.',
      );
    });

    test('multiple unit rows all with explore returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore, kWorkTargetProspect],
              'explorer-2': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'Fully Explore-enabled panel state — the existential check '
            'returns true on the first match, which is the documented '
            'short-circuit behavior.',
      );
    });

    test('explore mixed with empty target lists returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': <String>[],
              'unit-2': <String>[],
              'explorer-3': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'Empty target lists are skipped by `List.contains(...)` and '
            'must not short-circuit the iteration on the false arm; the '
            'trailing Explore row must still be discovered.',
      );
    });
  });

  registerExploreAssignSnapshotTrueGuardsAndDeterminismGroups();
}
