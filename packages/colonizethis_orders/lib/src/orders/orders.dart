/// Barrel: order suggestion/engine/application APIs (import reduction). Refs #1531.
library;

export 'build_rail_work_rules.dart';
export 'bundled_civilian_work_order.dart';
export 'civilian_work_affordance.dart';
// Refs #3753 R4b: the province-overlay UI reuses the Explorer Consulate-gate
// predicate + rejection reason so the disabled Explore/Prospect tooltip matches
// the order-engine submission gate (single source of truth).
export 'diplomatic_access_helpers.dart'
    show
        explorerConsulateGateBlocksMinorTribeProvince,
        kReasonConsulateRequiredForExplore;
export 'development_panel_assign.dart';
export 'development_panel_road_first.dart';
export 'development_panel/idle_civilians.dart'
    show idleDevelopmentCiviliansForAssign;
export 'development_panel/improve_tile_ordering.dart'
    show orderDevelopmentImproveTiles;
export 'development_panel/material_affordance.dart'
    show canAffordDevelopmentWorkOrder;
export 'development_counsel_ranking.dart';
export 'development_counsel_types.dart';
export 'draft_orders_mutations.dart';
export 'feedstock_bootstrap_cost.dart';
export 'feedstock_extraction_targets.dart';
export 'incremental_candidate_validator.dart';
export 'industry_counsel_core_snapshot.dart';
export 'industry_counsel_ranking.dart';
export 'military_counsel_affordance.dart';
export 'military_counsel_ranking.dart';
export 'military_counsel_types.dart';
export 'trade_counsel_emission.dart';
export 'trade_counsel_ranking.dart';
export 'naval_mission_availability.dart';
export 'naval_mission_targets.dart';
export 'order_effects_projector.dart';
export 'order_engine.dart';
export 'order_merge.dart';
export 'order_work_constants.dart';
export 'order_suggestion.dart';
export 'order_suggestion_api.dart';
export 'order_suggestion_api_impl.dart';
export 'order_suggestion_helpers.dart';
export 'order_validation_result.dart';
export 'order_validators.dart';
export 'order_visibility.dart';
export 'orders_application.dart';
export 'orders_application_context.dart'
    show
        appendMilitaryRegimentToArmy,
        spyBaseKillChancePercent,
        spyCounterEspionageKillBoostPercent,
        spyDeathDiplomacyPenalty,
        spyDefectionChancePercent,
        spyGarrisonKillChanceCapPercent,
        spyGarrisonKillChancePerRegiment,
        spyResearchBoostPerGp;
export 'orders_application_helpers.dart';
export 'projected_effects.dart';
export 'unit_type_helpers.dart' show devExclusiveReservedTileKeysForPlayer;
export 'validators/work_order_cost_calculator.dart';
export 'work_order_duration_preview.dart';
