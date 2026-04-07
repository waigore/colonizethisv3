/// Explicit logic surface consumed by `colonizethis_ai`.
///
/// This library intentionally avoids exporting the full logic barrel so AI can
/// depend on narrow contracts only.
library;

export 'src/ai/ai_control.dart' show isAiControlled;
export 'src/ai/simple_ai_heuristics.dart' show turnSeedForPlayer;
export 'src/constants.dart' show GamePlayerLookup;
export 'src/diplomacy/diplomacy_relation_lookup.dart'
    show
        getRelation,
        greatPowerPowerScore,
        provinceCountOwnedBy,
        shipCountForFaction;
export 'src/economy/worker_economy.dart' show effectiveLabourForWorkers;
export 'src/orders/draft_orders_mutations.dart'
    show applyArmyMoveOrderForPlayer;
export 'src/orders/order_suggestion_helpers.dart'
    show
        filterArmyMoveOrdersByDiplomacy,
        filterMoveOrdersByDiplomacy,
        getProvinceOwnerMap;
export 'src/world/player_view.dart' show PlayerView, buildPlayerView;
export 'src/world/province_lookup.dart' show allProvinces;
export 'src/world/unit_lookup.dart'
    show
        allUnitsFromWorld,
        regimentTypeCountsForPlayer,
        shipTypeCountsForPlayer;
