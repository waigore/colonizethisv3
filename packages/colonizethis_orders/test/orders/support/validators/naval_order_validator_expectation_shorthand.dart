// Compact NavalOrderValidator expectation shorthands (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_order_validator_test_support.dart';

const _novDefaultPlayer = Player(
  id: kNavalOrderValidatorTestPlayerId,
  displayName: 'P1',
  isHuman: true,
);

NavalOrderValidator novValidator({required Game game, required MapTopology topology}) =>
    navalOrderValidatorForTest(game: game, topology: topology);

NavalMoveOrder novSeaMove(String fleetId, String seaZoneId) =>
    NavalMoveOrder(fleetId: fleetId, destinationSeaZoneId: seaZoneId);

// dart format off
void _novExpectResult(
  OrderValidationResult result, {
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  bool reasonIsNull = false,
}) {
  expect(result.status, status);
  if (reasonExact != null) expect(result.reason, reasonExact);
  if (reasonContains != null) expect(result.reason, reasonContains);
  if (reasonIsNull) expect(result.reason, isNull);
}

void novExpectNavalMove({
  required NavalOrderValidator validator,
  required NavalMoveOrder order,
  bool previousRejected = false,
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  bool reasonIsNull = false,
}) => _novExpectResult(
  validator.validateNavalMove(order, previousRejected: previousRejected),
  status: status,
  reasonExact: reasonExact,
  reasonContains: reasonContains,
  reasonIsNull: reasonIsNull,
);

void novExpectNavalMission({
  required NavalOrderValidator validator,
  required NavalMissionOrder order,
  bool previousRejected = false,
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  bool reasonIsNull = false,
}) => _novExpectResult(
  validator.validateNavalMission(order, previousRejected: previousRejected),
  status: status,
  reasonExact: reasonExact,
  reasonContains: reasonContains,
  reasonIsNull: reasonIsNull,
);

void novExpectAtSeaMove({
  required MapTopology topology,
  required String destSea,
  required OrderValidationStatus status,
  String fleetId = 'f1',
  bool previousRejected = false,
  List<Fleet>? fleets,
  List<Player>? players,
  String? reasonExact,
  bool reasonIsNull = false,
}) => novExpectNavalMove(
  validator: novValidator(
    game: navalOrderValidatorTestGame(
      fleets: fleets ?? [navalOrderValidatorTestFleetAtSea(fleetId: fleetId)],
      players: players ?? const [_novDefaultPlayer],
    ),
    topology: topology,
  ),
  order: novSeaMove(fleetId, destSea),
  previousRejected: previousRejected,
  status: status,
  reasonExact: reasonExact,
  reasonIsNull: reasonIsNull,
);

void novExpectInPortMove({
  required MapTopology topology,
  required String destSea,
  required OrderValidationStatus status,
  String fleetId = 'f1',
  List<Fleet>? fleets,
  String? reasonExact,
  bool reasonIsNull = false,
}) => novExpectNavalMove(
  validator: novValidator(
    game: navalOrderValidatorTestGame(
      oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
      fleets: fleets ?? [navalOrderValidatorTestFleetInPort(fleetId: fleetId)],
    ),
    topology: topology,
  ),
  order: novSeaMove(fleetId, destSea),
  status: status,
  reasonExact: reasonExact,
  reasonIsNull: reasonIsNull,
);

void novExpectDockMove({
  required MapTopology topology,
  required OrderValidationStatus status,
  String fleetId = 'f1',
  String portLocalId = 'P1',
  List<Fleet>? fleets,
  List<Province>? oldWorldProvinces,
  List<Player>? players,
  NavalMoveOrder? order,
  String? reasonExact,
  bool reasonIsNull = false,
}) => novExpectNavalMove(
  validator: novValidator(
    game: navalOrderValidatorTestGame(
      oldWorldProvinces: oldWorldProvinces ?? [navalOrderValidatorTestOwnedProvince(portLocalId)],
      fleets: fleets ?? [navalOrderValidatorTestFleetAtSea(fleetId: fleetId)],
      players: players ?? const [_novDefaultPlayer],
    ),
    topology: topology,
  ),
  order: order ?? NavalMoveOrder(
    fleetId: fleetId,
    destinationPortProvinceId: ProvinceId.full(kNavalOrderValidatorTestRegionId, portLocalId),
  ),
  status: status,
  reasonExact: reasonExact,
  reasonIsNull: reasonIsNull,
);

MapTopology _novSingleSeaTopology() => navalOrderValidatorTestTopology(nodes: [navalOrderValidatorTestSeaNode('sea1')]);

NavalOrderValidator novAtSeaMissionValidator({List<Province> oldWorldProvinces = const [], List<Fleet>? fleets}) =>
    novValidator(
      game: navalOrderValidatorTestGame(
        oldWorldProvinces: oldWorldProvinces,
        fleets: fleets ?? [navalOrderValidatorTestFleetAtSea()],
      ),
      topology: _novSingleSeaTopology(),
    );
// dart format on
