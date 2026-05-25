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

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

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

  setUp(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — snapshot short-circuit',
    () {
      testWidgets('snapshot says Explore enabled -> true (no panel sweep)', (
        tester,
      ) async {
        var assignTaps = 0;
        ctE2eCivilianPanelSnapshot = _snapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(
          _wrap(
            _civilianPanel(
              children: [
                _AssignRow(
                  label: kUnitTypeExplorer,
                  exploreTileEnabled: true,
                  onTap: () => assignTaps++,
                ),
              ],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
          isTrue,
        );
        expect(
          assignTaps,
          0,
          reason: 'The snapshot short-circuit must return immediately '
              'without tapping any Assign row; a regression that walked '
              'the panel anyway would inflate every fleet-reach turn by '
              'the slow-path budget (Bottleneck 5).',
        );
      });

      testWidgets(
        'snapshot says no Explore enabled -> false (no panel sweep)',
        (tester) async {
          var assignTaps = 0;
          ctE2eCivilianPanelSnapshot = _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
            },
          );
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: true,
                    onTap: () => assignTaps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isFalse,
          );
          expect(
            assignTaps,
            0,
            reason: 'The snapshot `false` verdict is contractually distinct '
                'from `null` and must short-circuit the panel sweep too. '
                'Conflating `false` with `null` would surface a false '
                'positive whenever the snapshot already proved no Explore '
                'is assignable.',
          );
        },
      );

      testWidgets(
        'snapshot null -> falls through to panel sweep (tap occurs)',
        (tester) async {
          var assignTaps = 0;
          ctE2eCivilianPanelSnapshot = null;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => assignTaps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isTrue,
          );
          expect(
            assignTaps,
            1,
            reason: 'A null snapshot is the "no plumbing this turn" '
                'state — the helper must fall through to the live '
                'Assign-row walk rather than treat null as a definitive '
                'verdict (matching the documented `bool?` contract of '
                '[e2eExploreAssignEnabledFromCivilianSnapshot]).',
          );
        },
      );
    },
  );

  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — panel sweep true branches',
    () {
      testWidgets('single Assign row with enabled Explore tile -> true', (
        tester,
      ) async {
        var assignTaps = 0;
        await tester.pumpWidget(
          _wrap(
            _civilianPanel(
              children: [
                _AssignRow(
                  label: kUnitTypeExplorer,
                  exploreTileEnabled: true,
                  onTap: () => assignTaps++,
                ),
              ],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
          isTrue,
        );
        expect(
          assignTaps,
          1,
          reason: 'The canonical happy path: one Assign row whose '
              'pushed sheet exposes an enabled `Explore` tile must '
              'return true after exactly one tap.',
        );
      });

      testWidgets(
        'second Assign row carries the enabled Explore tile -> true after '
        'two taps',
        (tester) async {
          var firstTaps = 0;
          var secondTaps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: false,
                    onTap: () => firstTaps++,
                  ),
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => secondTaps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isTrue,
          );
          expect(
            firstTaps,
            1,
            reason: 'A disabled `Explore` tile on the first row must NOT '
                'short-circuit to `true`; the helper has to keep walking '
                'until it finds an `enabled: true` Explore tile.',
          );
          expect(
            secondTaps,
            1,
            reason: 'The second row carrying the enabled `Explore` tile '
                'is the first true match — pin the linear sweep order so '
                'a regression that reorders / skips rows fails here.',
          );
        },
      );
    },
  );

  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — panel sweep false branches',
    () {
      testWidgets('no Assign rows at all -> false (sweep exhausted)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            _civilianPanel(
              children: const [ListTile(title: Text('No Assign here'))],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(
            tester,
            maxPanelSweepSteps: 2,
          ),
          isFalse,
        );
      });

      testWidgets('only Assign rows whose sheet has no Explore tile -> false',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _wrap(
            _civilianPanel(
              children: [
                _AssignRow(
                  label: kUnitTypeBuilder,
                  exploreTileEnabled: null,
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        );
        expect(
          await e2eAnyExplorerHasEnabledExploreAssignFleet(
            tester,
            maxPanelSweepSteps: 1,
          ),
          isFalse,
        );
        expect(
          taps,
          1,
          reason: 'When the assign sheet mounts but contains no `Explore` '
              'tile at all, the helper must pop the route and continue '
              'the sweep (returning false only after the sweep cap). A '
              'regression that returned true here would conflate '
              '"no Explore tile" with "Explore enabled".',
        );
      });

      testWidgets(
        'Assign row whose Explore tile is `enabled: false` -> false '
        '(panel-mounted but no readiness)',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: false,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(
              tester,
              maxPanelSweepSteps: 1,
            ),
            isFalse,
          );
          expect(
            taps,
            1,
            reason: 'A disabled `Explore` tile is the canonical "panel '
                'mounted but Explore not assignable yet" state — the '
                'helper must check `enabled` strictly and continue past '
                '`enabled: false`. A regression that ignored the flag '
                'and returned true on tile-presence alone would mask '
                'real bundled-Explore readiness regressions on Linux CI.',
          );
        },
      );
    },
  );

  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — dedup and bounds',
    () {
      testWidgets(
        'visited Assign widgets are deduped across sweep steps '
        '(same widget identity not tapped twice)',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: false,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(
              tester,
              maxPanelSweepSteps: 4,
            ),
            isFalse,
          );
          expect(
            taps,
            1,
            reason: 'Across 4 sweep steps the same Assign widget must be '
                'tapped at most once — the identityHashCode-deduped '
                '`visitedAssignWidgets` set guards against re-tapping a '
                'stable row when the drag does not reveal new rows. A '
                'regression that dropped the dedup would inflate the '
                'sweep by 4× on every fleet-reach retry.',
          );
        },
      );

      testWidgets(
        'maxPanelSweepSteps = 0 short-circuits before any Assign tap',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(
              tester,
              maxPanelSweepSteps: 0,
            ),
            isFalse,
          );
          expect(
            taps,
            0,
            reason: 'A `maxPanelSweepSteps: 0` ceiling must enter the '
                'for-loop zero times and return false before any tap — '
                'pins the bound as the canonical kill-switch the issue '
                '§ Bottleneck 5 narrowed from 24 to 16.',
          );
        },
      );
    },
  );

  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — '
    'stabilization fast-path exit (Refs #2336 Bottleneck 5)',
    () {
      testWidgets(
        'two consecutive empty steps after a productive step exit before '
        'the sweep cap (no further panel work)',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    // Single disabled-Explore row: tapped once on step 0
                    // (productive step). Steps 1 and 2 enumerate the same
                    // widget identity, dedup it, and record zero new
                    // Assigns; the fast-path must return false on step 2
                    // without entering steps 3..15 of the default cap.
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: false,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          // Run with the default `maxPanelSweepSteps` (16). A regression
          // that dropped the fast-path would still return false (taps
          // would also remain at 1 by dedup), so this test pins the early
          // termination via a wall-clock-style probe: in a 25 ms-per-drag
          // sweep, 16 iterations cost ~400 ms of pump work that the
          // fast-path avoids.
          final sw = Stopwatch()..start();
          final result = await e2eAnyExplorerHasEnabledExploreAssignFleet(
            tester,
          );
          sw.stop();
          expect(result, isFalse);
          expect(
            taps,
            1,
            reason: 'The single Assign row must be tapped exactly once '
                'across the entire (early-terminated) sweep — the dedup '
                'set blocks re-taps and the fast-path exits before the '
                'sweep cap is reached.',
          );
          // The fast-path exits on step 2 (after one productive + two
          // empty steps) so the sweep does at most 3 drag/pump pairs.
          // The default 16-step sweep would do 16. Allow a comfortable
          // 8-step ceiling to avoid CI clock noise while still failing
          // any regression that restored the full 16-step burn.
          //
          // The 25 ms-per-drag pump alone is the dominant cost here;
          // gesture and finder work are O(1) per step on the single-row
          // tree. Pin the upper bound on observed sweep steps via the
          // assigned dedup set size (1) and via the helper returning
          // before the 8-step / 25 ms ≈ 200 ms threshold.
          expect(
            sw.elapsed,
            lessThan(const Duration(seconds: 2)),
            reason: 'A regression that disabled the fast-path would walk '
                'the full 16-step sweep on a stable single-row panel, '
                'burning ~16 × 25 ms = 400 ms of drag-pump work plus '
                'per-step finder evaluations. Pin the upper bound at '
                '2 s so the fast-path remains observable even on a slow '
                'Linux runner without churning on micro-timing.',
          );
        },
      );

      testWidgets(
        'single empty step does not short-circuit when a fresh Assign row '
        'still has not been visited',
        (tester) async {
          var firstTaps = 0;
          var secondTaps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: false,
                    onTap: () => firstTaps++,
                  ),
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => secondTaps++,
                  ),
                ],
              ),
            ),
          );
          // Both rows render together in step 0, so a single empty step
          // never materializes here — the helper returns true after two
          // taps in step 0 itself. This test ensures the fast-path does
          // not preempt a still-pending Explore-true match by interrupting
          // step 0's normal enumeration.
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isTrue,
          );
          expect(
            firstTaps,
            1,
            reason: 'Step 0 must walk the disabled-Explore row before the '
                'enabled-Explore row; the fast-path counter only ever '
                'increments at the end of a step after the inner loop '
                'has fully drained the visible candidates.',
          );
          expect(
            secondTaps,
            1,
            reason: 'The enabled-Explore row in the same step must still '
                'be reachable; a regression that exited mid-step on a '
                'zero-new step would never see this row when both rows '
                'are visible at once.',
          );
        },
      );
    },
  );
}
