/// Turn-resolution orchestrator: phase pipeline, resolver, end-of-turn rules.
/// SPEC/program/turn-resolution. Extracted from `colonizethis_logic` (Refs #3290 C3).
library colonizethis_turn;

export 'src/projections/order_projections.dart';
export 'src/turn/economy_debt_rules.dart';
// Funding RP/treasury rates and the industrial-bonus helper are surfaced so UI
// callers (e.g. the GAME40001 Technology slot turn-preview, Refs #3512) compute
// the same per-turn research effect the resolver applies, without duplicating
// the rate table (single source of truth — Refs #3472).
export 'src/turn/economy_tech_effects.dart';
export 'src/turn/pending_treasury_costs.dart';
export 'src/turn/research_resolver.dart';
export 'src/turn/research_rules.dart';
export 'src/turn/turn_news_digest.dart';
export 'src/turn/turn_resolution_result.dart';
export 'src/turn/turn_resolver.dart';
