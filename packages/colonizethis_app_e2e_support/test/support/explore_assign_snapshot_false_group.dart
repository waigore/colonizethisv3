// Shared fixtures + branch groups for e2eExploreAssignEnabledFromCivilianSnapshot
// (Refs #4598 Slice C densify).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRoad,
        kWorkTargetExplore,
        kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

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

void registerExploreAssignSnapshotNullAndFalseGroups() {
  group('e2eExploreAssignEnabledFromCivilianSnapshot — null branch', () {
    test('null snapshot returns null (NOT false)', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(null),
        isNull,
        reason:
            'No civilian-panel snapshot plumbing this turn must surface '
            'as `null` so the caller (`_anyExplorerHasEnabledExploreAssignFleetE2e`) '
            'falls back to the live panel walk instead of treating the '
            'missing snapshot as a definitive "enabled" / "disabled" '
            'verdict. Returning `false` here would silently skip the '
            'slow-path fallback and surface a false bundled-Explore '
            '"disabled" reading whenever the panel is mid-mount.',
      );
    });
  });

  group('e2eExploreAssignEnabledFromCivilianSnapshot — false branches', () {
    test('empty availableWorkTargets returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(_snapshot()),
        isFalse,
        reason:
            'A mounted civilian panel with zero unit rows is a definitive '
            '"panel mounted but no civilian can be assigned anything" '
            'verdict — the caller skips the slow-path Assign sweep. '
            'Returning `null` here would force an unnecessary panel-sweep '
            'on every fleet-reach turn.',
      );
    });

    test('single unit row with no explore target returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad, kWorkTargetProspect],
            },
          ),
        ),
        isFalse,
        reason:
            'A unit row with valid non-Explore work targets still does '
            'not satisfy the predicate — the panel-sweep fallback would '
            'find no Explore tile either, so `false` is the deterministic '
            'short-circuit.',
      );
    });

    test('multiple unit rows none with explore target returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
              'unit-2': [kWorkTargetProspect, kWorkTargetBuildImprovement],
              'unit-3': <String>[],
            },
          ),
        ),
        isFalse,
        reason:
            'Iteration walks every value list before returning false; an '
            'early return on the first non-matching row would skip later '
            'rows that could legitimately surface Explore (regression '
            'guard against accidental short-circuit on the false arm).',
      );
    });

    test('empty target lists for all rows returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': <String>[],
              'unit-2': <String>[],
            },
          ),
        ),
        isFalse,
        reason:
            'Empty target lists are valid panel states (every unit is '
            'busy / idle without an Explore-capable type). The predicate '
            'must traverse them without spuriously returning `true`.',
      );
    });
  });
}
