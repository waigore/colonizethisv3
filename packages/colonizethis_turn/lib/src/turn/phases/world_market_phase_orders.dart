// World-market order gathering / merge / restriction helpers (Refs #2990,
// #3416 part-of -> explicit library, #4168 wave-5 gather/capacity split).
// Imported by `world_market_phase.dart`; symbols stay unexported from the
// package barrel.

export 'world_market_order_gather.dart'
    show
        computeMinorTribeAutoOffers,
        computeMinorTribeTownManufacturingAutoOffers,
        mergeOrdersByFaction,
        restrictToFactions,
        splitTradeOrdersByType;
export 'world_market_phase_capacities.dart'
    show
        StartOfPhaseCapacities,
        applyLockRecoveryTreasuryViewForMarket,
        computeStartOfPhaseCapacities;
