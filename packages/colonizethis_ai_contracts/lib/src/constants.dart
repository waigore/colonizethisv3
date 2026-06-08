/// Shared constants re-export shim for the `colonizethis_ai_contracts` package.
///
/// Mirrors the historical `colonizethis_logic` `src/constants.dart` shim so the
/// moved `src/ai/` source keeps its `../constants.dart` import paths unchanged
/// after extraction (Refs #3290 C4). The symbols originate in
/// `colonizethis_models`, `colonizethis_world`, and `colonizethis_orders` — all
/// direct `colonizethis_ai_contracts` dependencies — so this introduces no new
/// dependency edge.
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
export 'package:colonizethis_orders/src/orders/order_work_constants.dart';
