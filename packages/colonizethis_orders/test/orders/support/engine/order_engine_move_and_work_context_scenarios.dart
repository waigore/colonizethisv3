// Table-driven OrderEngine move/work-context scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_move_and_work_context_expectations.dart';

/// One row in [orderEngineMoveAndWorkContextScenarios].
class OrderEngineMoveAndWorkContextScenario implements RefsScenario {
  const OrderEngineMoveAndWorkContextScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineMoveAndWorkContextTarget target;
  @override
  final String? refs;
}

void runOrderEngineMoveAndWorkContextScenario(
  OrderEngineMoveAndWorkContextScenario scenario,
) {
  runOrderEngineMoveAndWorkContextExpectation(scenario.target);
}

/// Canonical scenarios for OrderEngine move/work-context family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_move_and_work_context_part*_test.dart` descriptions.
List<OrderEngineMoveAndWorkContextScenario>
orderEngineMoveAndWorkContextScenarios() => const [
  OrderEngineMoveAndWorkContextScenario(
    label: 'move order rejected when destination province unknown',
    target: OrderEngineMoveAndWorkContextTarget
        .moveRejectedWhenDestinationProvinceUnknown,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order explore rejected when province unknown',
    target: OrderEngineMoveAndWorkContextTarget
        .workExploreRejectedWhenProvinceUnknown,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order explore rejected on foreign GP tile for explorer',
    target:
        OrderEngineMoveAndWorkContextTarget.workExploreRejectedOnForeignGpTile,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected when province not fogged or better',
    target: OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWhenProvinceNotFogged,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected when tile is not mineral-eligible',
    target: OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWhenNotMineralEligible,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'work order prospect accepted when mineral-eligible and visibility ok',
    target: OrderEngineMoveAndWorkContextTarget
        .workProspectAcceptedWhenMineralEligible,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'work order prospect rejected in Tribe province without a consulate (Refs #3753 R4)',
    target: OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWithoutConsulate,
    refs: '#3753',
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected on foreign GP tile for explorer',
    target:
        OrderEngineMoveAndWorkContextTarget.workProspectRejectedOnForeignGpTile,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'move order rejected when destination not adjacent and not own province',
    target:
        OrderEngineMoveAndWorkContextTarget.moveRejectedWhenNotAdjacentNotOwn,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'civilian move order accepted when destination not adjacent but own province',
    target: OrderEngineMoveAndWorkContextTarget
        .civilianMoveAcceptedWhenNotAdjacentOwnProvince,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected when tile already prospected',
    target: OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWhenAlreadyProspected,
  ),
];
