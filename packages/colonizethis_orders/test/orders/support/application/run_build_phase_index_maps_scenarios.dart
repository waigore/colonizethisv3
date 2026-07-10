// Table-driven runBuildPhase index-map scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'run_build_phase_index_maps_fixtures.dart';

void rbpiRunMilitarySingleHomeArmy() {
  const k = 3;
  final game = runBuildPhaseMilitaryGame(regimentCount: k);
  final orders = runBuildPhaseMilitaryOrders(regimentCount: k);

  final next = applyBuildAndWorkOrders(game, orders);

  expect(next.worldState.armies.length, 1);
  final army = next.worldState.armies.single;
  expect(army.id, homeArmyIdFor(runBuildPhasePlayerId));
  expect(army.isHomeArmy, isTrue);
  expect(army.regimentUnitIds.length, k);
}

void rbpiRunNavalSingleHomeFleet() {
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

List<RunnableScenario> runBuildPhaseIndexMapsScenarios() => const [
  RunnableScenario(
    label:
        'consecutive military recruits build one home army with all regiments',
    run: rbpiRunMilitarySingleHomeArmy,
  ),
  RunnableScenario(
    label:
        'consecutive ship recruits add ships to a single home fleet (cache reuse)',
    run: rbpiRunNavalSingleHomeFleet,
  ),
];
