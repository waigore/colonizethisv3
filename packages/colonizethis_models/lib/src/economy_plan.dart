// Economy planner output types. SPEC/ai/economy-planner.md.

import 'assigned_recipe.dart';
import 'world_market.dart';

/// Cargo preference for naval/build planners. SPEC/ai/economy-planner.md.
enum CargoPreference { none, preferCargo, strongCargo }

/// Result of the economy planner for one AI player.
class EconomyPlan {
  const EconomyPlan({
    required this.productionAssignments,
    required this.cargoPreference,
    this.tradeOrders = const <TradeOrder>[],
  });

  /// Labour assignments per recipe for the Production phase.
  final List<AssignedRecipe> productionAssignments;

  /// Preference for cargo capacity (join home fleet / build merchants).
  final CargoPreference cargoPreference;

  /// World Market bids/offers for the market phase. SPEC/ai/treasury-planner.md.
  final List<TradeOrder> tradeOrders;
}
