// Fixtures for e2eEnsureNonHomeFleetInNwAfterLoop pins (#4598).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String ensureNonHomeHuman = 'gp1';

const TurnState ensureNonHomeOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData ensureNonHomeEmptyRegion = RegionData();
const Orders ensureNonHomeEmptyOrders = Orders();
const MapTopology ensureNonHomeEmptyTopology = MapTopology();

Fleet ensureNonHomeHomeFleet() => Fleet(
  id: 'fleet_$ensureNonHomeHuman',
  ownerId: ensureNonHomeHuman,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|capital',
);

Fleet ensureNonHomeSplitFleetInNw({String id = 'fleet_split'}) => Fleet(
  id: id,
  ownerId: ensureNonHomeHuman,
  regionId: 'newWorld',
  seaZoneId: 'nwSea',
);

Game ensureNonHomeGameWithFleets(List<Fleet> fleets) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: ensureNonHomeOrderingTurn,
    oldWorld: ensureNonHomeEmptyRegion,
    newWorld: ensureNonHomeEmptyRegion,
    fleets: fleets,
  ),
  players: const [
    Player(id: ensureNonHomeHuman, displayName: 'You', isHuman: true),
  ],
);

CtE2eNavalPanelSnapshot ensureNonHomeSnapshot({required List<Fleet> fleets}) =>
    CtE2eNavalPanelSnapshot(
      game: ensureNonHomeGameWithFleets(fleets),
      humanPlayerId: ensureNonHomeHuman,
      topology: ensureNonHomeEmptyTopology,
      draftOrders: ensureNonHomeEmptyOrders,
    );

CtE2eNavalPanelSnapshot ensureNonHomeReachedSnapshot() => ensureNonHomeSnapshot(
  fleets: [ensureNonHomeHomeFleet(), ensureNonHomeSplitFleetInNw()],
);

CtE2eNavalPanelSnapshot ensureNonHomeHomeOnlySnapshot() =>
    ensureNonHomeSnapshot(fleets: [ensureNonHomeHomeFleet()]);

/// Pumps an effectively empty material app — no naval panel, no region
/// tab, no rail buttons. Exercises the snapshot-only short-circuit
/// branch where `e2eOpenNavalPanel` is skipped.
/// Pumps a tree with the naval panel root key already mounted so the
/// helper's conditional `e2eOpenNavalPanel` call short-circuits via the
/// hit-testable panel check without needing an empire-rail button.
///
/// Uses a [Container] with an explicit color so the underlying
/// `RenderConstrainedBox` responds to hit-testing — a bare [SizedBox]
/// is not hit-testable and the helper would time out trying to find
/// an empire-rail / first-fleet-marker opener instead.
Future<void> pumpEnsureNonHomeNavalPanelMounted(WidgetTester tester) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            key: kCtE2ENavalPanelRootKey,
            color: const Color(0xFF000000),
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
