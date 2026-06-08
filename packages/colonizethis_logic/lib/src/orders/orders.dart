/// Barrel: order suggestion/engine/application APIs (import reduction). Refs #1531.
library;

export 'build_rail_work_rules.dart';
export 'draft_orders_mutations.dart';
export 'incremental_candidate_validator.dart';
export 'order_engine.dart';
export 'order_merge.dart';
export 'order_work_constants.dart';
export '../projections/order_projections.dart';
export 'order_suggestion.dart';
export 'order_suggestion_api.dart';
export 'order_suggestion_api_impl.dart';
export 'order_suggestion_helpers.dart';
export 'order_validation_result.dart';
export 'order_validators.dart';
export 'order_visibility.dart';
export 'orders_application.dart';
export 'orders_application_context.dart' show appendMilitaryRegimentToArmy;
export 'orders_application_helpers.dart';
export '../projections/projected_effects.dart';
export 'work_order_duration_preview.dart';
