// Table-driven OrderEngine civilian move XOR work scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_civilian_move_xor_work_run_rows.dart';

/// One row in [orderEngineCivilianMoveXorWorkScenarios].
class OrderEngineCivilianMoveXorWorkScenario implements RefsScenario {
  const OrderEngineCivilianMoveXorWorkScenario({
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

void runOrderEngineCivilianMoveXorWorkScenario(
  OrderEngineCivilianMoveXorWorkScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for civilian move XOR work family.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_civilian_move_xor_work_test.dart` descriptions.
List<OrderEngineCivilianMoveXorWorkScenario>
orderEngineCivilianMoveXorWorkScenarios() => const [
  OrderEngineCivilianMoveXorWorkScenario(
    label: 'rejects work when same civilian already has a move order',
    run: oecmxwRunRejectsWorkWhenMoveExists,
  ),
  OrderEngineCivilianMoveXorWorkScenario(
    label: 'merged draft with move then work rejects work (move remains valid)',
    run: oecmxwRunMergedDraftMoveThenWork,
  ),
];
