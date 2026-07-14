// Compact MoveValidator / ArmyMoveValidator expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

// dart format off
const mvMinor1 = MinorNation(id: 'minor1', displayName: 'Minor');
const mvMinor1Capital = MinorNation(id: 'minor1', displayName: 'Minor1', capitalProvinceId: 'oldWorld|P2');
const mvTribe1Capital = Tribe(id: 'tribe1', displayName: 'Tribe1', capitalProvinceId: 'newWorld|P2');

MapTopology mvOwNwProvinceTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [],
);
// dart format on

void mvExpectUnitMove({
  required Game game,
  required MapTopology topology,
  required String unitId,
  required String destinationTileKey,
  bool previousRejected = false,
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
}) {
  const validator = MoveValidator();
  final result = validator.validate(
    MoveOrder(unitId: unitId, destinationTileKey: destinationTileKey),
    game,
    'p1',
    moveValidatorTestContext(game, topology, 'p1'),
    const [],
    topology,
    previousRejected: previousRejected,
  );
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
}

void mvExpectArmyMove({
  required Game game,
  required MapTopology topology,
  required String armyProvinceId,
  required String destinationProvinceId,
  List<DiplomaticOrder> draftOrders = const [],
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  List<Matcher>? reasonContainsAll,
}) {
  final view = buildPlayerView(game, topology, 'p1');
  const validator = ArmyMoveValidator();
  final result = validator.validate(
    ArmyMoveOrder(
      armyId: fieldArmyIdFor('p1', armyProvinceId),
      destinationProvinceId: destinationProvinceId,
    ),
    game,
    'p1',
    draftOrders,
    view,
    topology,
  );
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
  for (final matcher in reasonContainsAll ?? const <Matcher>[]) {
    expect(result.reason, matcher);
  }
}
