/// Pins the widget-tree contract of
/// [e2eAnyExplorerHasEnabledExploreAssignFleet]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet bundled-Explore retry loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper
/// through the AC1 barrel alias `anyExplorerHasEnabledExploreAssignFleet`
/// inside a bounded retry window (`maxBoundedTurnRetries = 8`). A silent
/// rename / fail-open here would either:
///
///   - Stall the retry loop on the slow `maxPanelSweepSteps (16) ×
///     per-step Assign sweep` path — Bottleneck 5 in
///     `SPEC/program/e2e-integration-tests.md` § Determinism — burning
///     wall-clock the snapshot short-circuit already avoids; or
///   - Silently flip the bundled-Explore readiness verdict (always-true
///     / always-false) and mask a real production regression.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';


part 'support/any_explorer_g1_part.dart';
part 'support/any_explorer_g2_part.dart';
part 'support/any_explorer_g3_part.dart';
part 'support/any_explorer_g4_part.dart';
part 'support/any_explorer_g5_part.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

Game _game() => const Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot _snapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

/// Builder for an Assign row that, when tapped, shows a modal route whose
/// tree contains an `Explore` [ListTile] with the given [exploreTileEnabled]
/// flag. Uses `showDialog` (a modal overlay) so the underlying civilian
/// panel ListView stays mounted in the tree between iterations — the
/// helper's `tester.drag(panelScrollable, ...)` between sweep steps needs
/// the panel root to remain reachable. The production civilian panel
/// likewise sits behind a modal-style assign sheet, not a full-screen push
/// route, so this mock is more faithful to the live surface as well.
class _AssignRow extends StatelessWidget {
  const _AssignRow({
    required this.label,
    this.exploreTileEnabled,
    this.onTap,
  });

  /// Visible label to disambiguate rows in failure messages.
  final String label;

  /// `null` → tapping shows a dialog WITHOUT an `Explore` tile (the helper
  /// walks past this row).
  /// non-null → tapping shows a dialog WITH an `Explore` [ListTile] whose
  /// `enabled` matches this flag.
  final bool? exploreTileEnabled;

  /// Optional spy invoked each time the Assign button is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () {
              onTap?.call();
              final tiles = <Widget>[];
              if (exploreTileEnabled != null) {
                tiles.add(
                  ListTile(
                    title: const Text('Explore'),
                    enabled: exploreTileEnabled!,
                  ),
                );
              } else {
                tiles.add(const ListTile(title: Text('Build Road')));
              }
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(child: Column(children: tiles)),
              );
            },
            // Non-const so each row's `Text('Assign')` has its own widget
            // identity. The helper's
            // `visitedAssignWidgets.add(identityHashCode(...))` dedup pin
            // requires distinct Text instances per Assign row — Dart
            // canonicalizes `const Text('Assign')` literals and would make
            // the dedup set collapse rows that the live panel renders
            // separately.
            // ignore: prefer_const_constructors
            child: Text('Assign'),
          );
        },
      ),
    );
  }
}

/// Wraps panel children under [kCtE2ECivilianPanelRootKey] with a single
/// [ListView] descendant, matching the helper's `find.descendant(of: root,
/// matching: find.byType(ListView))` precondition.
Widget _civilianPanel({required List<Widget> children}) => KeyedSubtree(
  key: kCtE2ECivilianPanelRootKey,
  child: ListView(children: children),
);

Widget _wrap(Widget body) => MaterialApp(home: Scaffold(body: body));


void main() {
  suppressLogsForTests();
  registerAnyExplorerG1Group();
  registerAnyExplorerG2Group();
  registerAnyExplorerG3Group();
  registerAnyExplorerG4Group();
  registerAnyExplorerG5Group();
}
