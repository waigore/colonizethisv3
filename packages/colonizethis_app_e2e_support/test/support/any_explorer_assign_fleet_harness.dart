library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'e2e_widget_pump_harness.dart';

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

CtE2eCivilianPanelSnapshot snapshot({
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
class AssignRow extends StatelessWidget {
  const AssignRow({required this.label, this.exploreTileEnabled, this.onTap});

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
Widget civilianPanel({required List<Widget> children}) => KeyedSubtree(
  key: kCtE2ECivilianPanelRootKey,
  child: ListView(children: children),
);

Widget wrap(Widget body) => wrapE2eScaffold(body);
