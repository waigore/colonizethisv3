// Hidden agenda modifiers for goal and order weighting. SPEC/ai/hidden-agendas.md.
//
// Re-exporting the data-layer contract avoids pass-through wrappers.
export 'package:colonizethis_data/colonizethis_data.dart'
    show
        getAgendaAllianceAcceptanceModifier,
        getAgendaBuildOrderModifier,
        getAgendaConquerModifier,
        getAgendaDiplomacyModifier,
        getAgendaPeaceAcceptanceModifier,
        getAgendaResearchModifier,
        getAgendaSpyOrderModifier,
        getAgendaTreatyBreakingModifier;
