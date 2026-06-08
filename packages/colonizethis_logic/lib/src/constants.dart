/// Shared constants and helpers for the colonizethis_logic package.
///
/// The order/work-domain constants (work targets, mineral-resource ids,
/// prospectability helpers) now live in the `orders` domain at
/// `orders/order_work_constants.dart` (Refs #3290 — `colonizethis_orders`
/// extraction prerequisite). This file re-exports them so existing
/// `package:colonizethis_logic` consumers keep their import paths unchanged.
library;

export 'package:colonizethis_models/colonizethis_models.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeRailBuilder,
        kUnitTypeSpy;
export 'package:colonizethis_world/colonizethis_world.dart'
    show
        GamePlayerLookup,
        kGridNeighborsCardinal4,
        kRegionNewWorld,
        kRegionOldWorld;
export 'orders/order_work_constants.dart';
