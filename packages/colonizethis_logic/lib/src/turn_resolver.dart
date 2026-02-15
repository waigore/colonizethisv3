import 'package:colonizethis_models/colonizethis_models.dart';

/// Resolution sequence. SPEC/program/turn-resolution: order of phases.
const List<TurnPhase> turnResolutionSequence = [
  TurnPhase.orders,
  TurnPhase.economy,
  TurnPhase.movement,
  TurnPhase.combat,
  TurnPhase.diplomacy,
  TurnPhase.endOfTurn,
];

/// Turn resolver stub. Runs phase sequence; only endOfTurn advances turn number.
/// SPEC/program/turn-resolution: Phase 1 stub, no economy/combat/diplomacy logic.
WorldState resolveTurn(WorldState current) {
  WorldState state = current;
  for (final phase in turnResolutionSequence) {
    state = _runPhase(state, phase);
  }
  return state;
}

WorldState _runPhase(WorldState state, TurnPhase phase) {
  switch (phase) {
    case TurnPhase.orders:
    case TurnPhase.economy:
    case TurnPhase.movement:
    case TurnPhase.combat:
    case TurnPhase.diplomacy:
      return state;
    case TurnPhase.endOfTurn:
      return state.copyWith(
        turnState: state.turnState.copyWith(
          turnNumber: state.turnState.turnNumber + 1,
          phase: TurnPhase.orders,
        ),
      );
  }
}
