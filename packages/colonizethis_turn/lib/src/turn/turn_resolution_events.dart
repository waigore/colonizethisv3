/// Emits game events after turn resolution phases. SPEC/program/game-events.md.
/// Keeps turn_resolver switch thin by moving event emission here.
library;

export 'turn_resolution_events_common.dart'
    show sortedPlayerIdsForTurnEvents;
export 'turn_resolution_events_diplomacy.dart'
    show
        emitDiplomacyChangeEvents,
        emitOvertureAdvancedEvents,
        emitProvinceCapturedEvents,
        emitVictorySetEvent;
export 'turn_resolution_events_discovery.dart'
    show emitPlayerDiscoveryEvents, emitWorkOrderCompletedEvents;
export 'turn_resolution_events_research.dart' show emitResearchCompleteEvents;
export 'turn_resolution_events_spy.dart' show emitSpyResolutionEvents;
