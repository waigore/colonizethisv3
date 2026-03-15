/// Shared unit-type predicates for orders. SPEC/program/orders.md § Work orders.
/// Used by WorkOrderValidator and OrderEngine for dev-exclusive tile tracking.

/// True for Builder, Engineer, Merchant: at most one work order per tile per player.
bool isDevExclusiveUnitType(String type) =>
    type == 'Builder' || type == 'Engineer' || type == 'Merchant';
