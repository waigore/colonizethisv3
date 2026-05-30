import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

/// World Market phase (phase 13) — gather submitted trade orders, run
/// per-commodity priority-queue deal matching, apply commodity / treasury /
/// cargo transfers, and roll unfilled orders forward as carry-forwards.
///
/// SPEC: `SPEC/program/turn-resolution-phases.md` § Phase 13 World Market
/// and `SPEC/program/world-market-resolution.md` (matching, pricing, FTP,
/// first-right-of-refusal, persistence).
///
/// **Slice scope (Refs #2990 B0+B1+B4 stub):** This handler exists to take
/// its slot in `turnResolutionSequence` between `buildWork` (phase 12) and
/// `endOfTurn` (phase 14) and to satisfy the phase-dispatch registry
/// contract (every phase in the sequence must have a registered handler or
/// `assertTurnPhaseHandlerRegistryComplete()` raises `StateError`). The
/// matching, pricing, and carry-forward logic — and the `WorldMarketState`
/// game-model wiring — are introduced by issue #2989 (data types and core
/// engine) and #2990 B2/B3/B5 (pipeline-state wiring, full handler, and
/// integration tests). Until those land, this handler is a pure no-op: it
/// does not mutate `Game`, does not transfer commodities or treasury, does
/// not modify cargo, and does not generate carry-forward orders, satisfying
/// the AC for an empty-orders turn from #2990 by construction.
TurnPhaseStepOutcome worldMarketTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) => TurnPhaseStepContinue(acc);
