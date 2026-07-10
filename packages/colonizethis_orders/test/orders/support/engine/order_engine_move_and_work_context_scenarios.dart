// Table-driven OrderEngine move/work-context scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_move_and_work_context_run_rows.dart';

/// One row in [orderEngineMoveAndWorkContextScenarios].
class OrderEngineMoveAndWorkContextScenario implements RefsScenario {
  const OrderEngineMoveAndWorkContextScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderEngineMoveAndWorkContextScenario(
  OrderEngineMoveAndWorkContextScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for OrderEngine move/work-context family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_move_and_work_context_part*_test.dart` descriptions.
List<OrderEngineMoveAndWorkContextScenario>
orderEngineMoveAndWorkContextScenarios() => const [
  OrderEngineMoveAndWorkContextScenario(
    label: 'move order rejected when destination province unknown',
    run: oemwcRunMoveRejectedWhenDestinationProvinceUnknown,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order explore rejected when province unknown',
    run: oemwcRunWorkExploreRejectedWhenProvinceUnknown,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order explore rejected on foreign GP tile for explorer',
    run: oemwcRunWorkExploreRejectedOnForeignGpTile,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected when province not fogged or better',
    run: oemwcRunWorkProspectRejectedWhenProvinceNotFogged,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected when tile is not mineral-eligible',
    run: oemwcRunWorkProspectRejectedWhenNotMineralEligible,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'work order prospect accepted when mineral-eligible and visibility ok',
    run: oemwcRunWorkProspectAcceptedWhenMineralEligible,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'work order prospect rejected in Tribe province without a consulate (Refs #3753 R4)',
    run: oemwcRunWorkProspectRejectedWithoutConsulate,
    refs: '#3753',
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected on foreign GP tile for explorer',
    run: oemwcRunWorkProspectRejectedOnForeignGpTile,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'move order rejected when destination not adjacent and not own province',
    run: oemwcRunMoveRejectedWhenNotAdjacentNotOwn,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label:
        'civilian move order accepted when destination not adjacent but own province',
    run: oemwcRunCivilianMoveAcceptedWhenNotAdjacentOwnProvince,
  ),
  OrderEngineMoveAndWorkContextScenario(
    label: 'work order prospect rejected when tile already prospected',
    run: oemwcRunWorkProspectRejectedWhenAlreadyProspected,
  ),
];
