/// Pins the widget-tree contract of [e2eNavalPanelShowsNonHomeFleetInNewWorld]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach harness fallback (`_harnessDetectsNonHomeFleetInNewWorld` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`) consults this
/// predicate when [ctE2eNavalPanelSnapshot] is null. A silent rename / fail-open
/// would stall the suite at `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s`
/// (Refs GitHub #2336 Bottleneck 4 / AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

Widget _navalPanel({required List<Widget> fleetTiles}) => KeyedSubtree(
  key: kCtE2ENavalPanelRootKey,
  child: Column(children: fleetTiles),
);

ExpansionTile _fleetTile({required String fleetTitle, String? locationLine}) =>
    ExpansionTile(
      title: Text(fleetTitle),
      subtitle: locationLine == null ? null : Text(locationLine),
    );

void main() {
  suppressLogsForTests();

  group('e2eNavalPanelShowsNonHomeFleetInNewWorld — false branches', () {
    testWidgets('no naval panel root key', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('empty'))),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isFalse);
    });

    testWidgets('naval panel with no ExpansionTile children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(fleetTiles: const [Text('loading')]),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isFalse);
    });

    testWidgets('home fleet only (no Fleet prefix title)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(
              fleetTiles: [
                ExpansionTile(
                  title: const Text('Home Fleet'),
                  subtitle: const Text('New World — Outer Sea'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isFalse);
    });

    testWidgets('non-home fleet without New World location line', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(
              fleetTiles: [
                _fleetTile(
                  fleetTitle: 'Fleet 2',
                  locationLine: 'Old World — Coastal Sea',
                ),
              ],
            ),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isFalse);
    });

    testWidgets('non-home fleet with no subtitle location', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(fleetTiles: [_fleetTile(fleetTitle: 'Fleet 2')]),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isFalse);
    });

    testWidgets('Fleet title prefix required (reject "Flotilla 2")', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(
              fleetTiles: [
                _fleetTile(
                  fleetTitle: 'Flotilla 2',
                  locationLine: 'New World — Outer Sea',
                ),
              ],
            ),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isFalse);
    });
  });

  group('e2eNavalPanelShowsNonHomeFleetInNewWorld — true branches', () {
    testWidgets('single non-home fleet with em-dash NW location', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(
              fleetTiles: [
                _fleetTile(
                  fleetTitle: 'Fleet 2',
                  locationLine: 'New World — Outer Sea',
                ),
              ],
            ),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isTrue);
    });

    testWidgets('home fleet row skipped; qualifying fleet is second tile', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(
              fleetTiles: [
                const ExpansionTile(title: Text('Home Fleet')),
                _fleetTile(
                  fleetTitle: 'Fleet 3',
                  locationLine: 'New World - Outer Sea',
                ),
              ],
            ),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isTrue);
    });

    testWidgets('first qualifying tile short-circuits (existential check)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _navalPanel(
              fleetTiles: [
                _fleetTile(
                  fleetTitle: 'Fleet 1',
                  locationLine: 'New World — Sea A',
                ),
                _fleetTile(
                  fleetTitle: 'Fleet 2',
                  locationLine: 'Old World — Coastal Sea',
                ),
              ],
            ),
          ),
        ),
      );
      expect(e2eNavalPanelShowsNonHomeFleetInNewWorld(tester), isTrue);
    });
  });
}
