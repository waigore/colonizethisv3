/// Explicit logic surface consumed by `colonizethis_debug_console`.
///
/// This library intentionally avoids exporting the full logic barrel so debug
/// console code can depend on narrow contracts only.
library;

export 'package:colonizethis_models/colonizethis_models.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeRailBuilder,
        kUnitTypeSpy;
export 'src/debug_console/debug_console_commodities.dart'
    show
        debugConsoleSupportedCommodityIds,
        debugConsoleSupportedCommodityIdsSorted;
export 'src/debug_console/debug_console_regiments.dart'
    show
        debugConsoleSupportedRegimentTypeIds,
        debugConsoleSupportedRegimentTypeIdsSorted;
export 'src/debug_console/debug_console_ships.dart'
    show
        debugConsoleSupportedShipTypeIds,
        debugConsoleSupportedShipTypeIdsSorted;
export 'src/debug_console/debug_console_workers.dart'
    show
        debugConsoleSupportedWorkerTierIds,
        debugConsoleSupportedWorkerTierIdsSorted;
export 'src/orders/build_spawn_province.dart' show resolveCivilianSpawnTileKey;
