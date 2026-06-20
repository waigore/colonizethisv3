/// Pins the fleet-reach short-circuit helpers
/// [e2eFleetReachDoneFromCtSnapshotOnly] and
/// [e2eHarnessDetectsNonHomeFleetInNewWorld]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach turn loop and final assertions depend on these entrypoints
/// to terminate within `_kMaxNextTurnTapsForNwFleetReach (35)` when the split
/// fleet enters the New World (Refs GitHub #2336 Bottleneck 4 / AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
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

const RegionData _emptyRegion = RegionData();

const Orders _emptyOrders = Orders();

const MapTopology _emptyTopology = MapTopology();

Game _gameWithFleets(List<Fleet> fleets) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: _emptyRegion,
    newWorld: _emptyRegion,
    fleets: fleets,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _snapshot({
  required List<Fleet> fleets,
  MapTopology topology = _emptyTopology,
}) => CtE2eNavalPanelSnapshot(
  game: _gameWithFleets(fleets),
  humanPlayerId: _human,
  topology: topology,
  draftOrders: _emptyOrders,
);

Fleet _homeFleet() => Fleet(
  id: 'fleet_$_human',
  ownerId: _human,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|capital',
);

Fleet _splitFleetInNw({String id = 'fleet_split'}) =>
    Fleet(id: id, ownerId: _human, regionId: 'newWorld', seaZoneId: 'nwSea');

Widget _navalPanelWithNwFleet() => KeyedSubtree(
  key: kCtE2ENavalPanelRootKey,
  child: Column(
    children: [
      ExpansionTile(
        title: const Text('Fleet 2'),
        subtitle: const Text('New World — Outer Sea'),
      ),
    ],
  ),
);

void main() {
  suppressLogsForTests();

  group('e2eFleetReachDoneFromCtSnapshotOnly', () {
    test('null snapshot returns false', () {
      expect(e2eFleetReachDoneFromCtSnapshotOnly(null), isFalse);
    });

    test(
      'matches e2eNonHomeHumanFleetInNewWorldFromCtSnapshot for NW split fleet',
      () {
        final snap = _snapshot(fleets: [_homeFleet(), _splitFleetInNw()]);
        expect(
          e2eFleetReachDoneFromCtSnapshotOnly(snap),
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(snap),
        );
        expect(e2eFleetReachDoneFromCtSnapshotOnly(snap), isTrue);
      },
    );

    test('home fleet only returns false', () {
      expect(
        e2eFleetReachDoneFromCtSnapshotOnly(_snapshot(fleets: [_homeFleet()])),
        isFalse,
      );
    });
  });

  group('e2eHarnessDetectsNonHomeFleetInNewWorld', () {
    testWidgets('snapshot true short-circuits without naval panel widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('no panel'))),
      );
      final snap = _snapshot(fleets: [_homeFleet(), _splitFleetInNw()]);
      expect(e2eHarnessDetectsNonHomeFleetInNewWorld(tester, snap), isTrue);
    });

    testWidgets('non-null snapshot false does not consult widget fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _navalPanelWithNwFleet())),
      );
      final snap = _snapshot(fleets: [_homeFleet()]);
      expect(
        e2eHarnessDetectsNonHomeFleetInNewWorld(tester, snap),
        isFalse,
        reason:
            'When snapshot plumbing is present but reports no arrival, the '
            'harness must not treat a coincidental NW location line in the '
            'widget tree as arrival — that would mask a stale snapshot.',
      );
    });

    testWidgets('null snapshot falls back to naval panel widget tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _navalPanelWithNwFleet())),
      );
      expect(e2eHarnessDetectsNonHomeFleetInNewWorld(tester, null), isTrue);
    });

    testWidgets('null snapshot and empty tree returns false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('empty'))),
      );
      expect(e2eHarnessDetectsNonHomeFleetInNewWorld(tester, null), isFalse);
    });
  });
}
