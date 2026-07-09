// runBuildPhase O(1) index-map assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'run_build_phase_index_maps_fixtures.dart';

/// Pins for [runBuildPhaseIndexMapsScenarios] rows.
enum RunBuildPhaseIndexMapsTarget {
  militarySingleHomeArmy,
  navalSingleHomeFleet,
}

void runRunBuildPhaseIndexMapsExpectation(RunBuildPhaseIndexMapsTarget target) {
  switch (target) {
    case RunBuildPhaseIndexMapsTarget.militarySingleHomeArmy:
      const k = 3;
      final game = runBuildPhaseMilitaryGame(regimentCount: k);
      final orders = runBuildPhaseMilitaryOrders(regimentCount: k);

      final next = applyBuildAndWorkOrders(game, orders);

      expect(next.worldState.armies.length, 1);
      final army = next.worldState.armies.single;
      expect(army.id, homeArmyIdFor(runBuildPhasePlayerId));
      expect(army.isHomeArmy, isTrue);
      expect(army.regimentUnitIds.length, k);

    case RunBuildPhaseIndexMapsTarget.navalSingleHomeFleet:
      const k = 2;
      final game = runBuildPhaseNavalGame(shipCount: k);
      final orders = runBuildPhaseNavalOrders(shipCount: k);

      final next = applyBuildAndWorkOrders(
        game,
        orders,
        topology: runBuildPhaseNavalTopology,
      );

      final ownedFleets = next.worldState.fleets
          .where((f) => f.ownerId == runBuildPhasePlayerId)
          .toList();
      expect(ownedFleets.length, 1);
      expect(ownedFleets.single.shipTypeIds.length, k);
  }
}
