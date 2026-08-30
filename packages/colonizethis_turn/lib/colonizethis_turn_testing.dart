/// Dev/test export surface for phase handlers, pipeline state, event sinks, and
/// other turn internals reached by package tests without `src/` imports.
/// SPEC/program/repo-lint.md (`repo.turn_test_no_src_imports`, Refs #4252).
library colonizethis_turn_testing;

export 'src/turn/combat_medal_gain_events.dart';
export 'src/turn/economy_turn_summary_events.dart';
export 'src/turn/end_of_turn_resolver.dart';
export 'src/turn/naval_resolution.dart';
export 'src/turn/naval_resolution_battle.dart';
export 'src/turn/phases/diplomacy_phase.dart';
export 'src/turn/phases/extraction_phase.dart';
export 'src/turn/phases/movement_phase.dart';
export 'src/turn/phases/movement_phase_bundled_work.dart';
export 'src/turn/phases/riches_to_treasury_phase.dart';
export 'src/turn/phases/world_market_phase.dart';
export 'src/turn/phases/world_market_phase_carry_forward.dart';
export 'src/turn/phases/world_market_phase_deals.dart';
export 'src/turn/phases/world_market_phase_orders.dart';
export 'src/turn/spy_resolver.dart';
export 'src/turn/turn_event_sink.dart';
export 'src/turn/turn_logging.dart';
export 'src/turn/turn_order_acceptance.dart';
export 'src/turn/turn_phase_handler_registry.dart';
export 'src/turn/turn_phase_runner.dart';
export 'src/turn/turn_pipeline_state.dart';
export 'src/turn/turn_resolution_events.dart';
export 'src/turn/turn_resolution_helpers.dart';
export 'src/turn/turn_resolution_seeds.dart';
export 'src/turn/turn_resolution_sequence.dart';
export 'src/turn/turn_resolver_config.dart';
