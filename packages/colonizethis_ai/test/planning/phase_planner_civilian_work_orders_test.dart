// Unit tests for `phase_planner_civilian_work_orders.dart` (Refs #2509 S5).
// Case bodies: `phase_planner_civilian_work_orders_*_cases.dart`.

import 'phase_planner_civilian_work_orders_adapter_cases.dart';
import 'phase_planner_civilian_work_orders_routing_cases.dart';

void main() {
  registerPhasePlannerCivilianWorkOrdersRoutingCases();
  registerPhasePlannerCivilianWorkOrdersAdapterCases();
}
