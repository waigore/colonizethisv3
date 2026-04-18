// Strategic full-AI order generation result. SPEC/ai/economy-planner.md.

import 'economy_plan.dart';
import 'orders.dart';

/// Result of strategic order generation: orders and economy plan. SPEC/ai/economy-planner.md.
class StrategicOrderResult {
  const StrategicOrderResult({required this.orders, required this.economyPlan});
  final Orders orders;
  final EconomyPlan economyPlan;
}
