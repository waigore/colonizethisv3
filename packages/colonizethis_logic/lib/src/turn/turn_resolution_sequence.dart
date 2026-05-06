import 'package:colonizethis_models/colonizethis_models.dart';

/// Resolution sequence. SPEC/program/turn-resolution-phases.md
const List<TurnPhase> turnResolutionSequence = [
  TurnPhase.orders,
  TurnPhase.extraction,
  TurnPhase.richesToTreasury,
  TurnPhase.consumption,
  TurnPhase.production,
  TurnPhase.diplomacy,
  TurnPhase.research,
  TurnPhase.movement,
  TurnPhase.minorRegimentUpgrade,
  TurnPhase.navalInterceptionCombat,
  TurnPhase.combat,
  TurnPhase.buildWork,
  TurnPhase.endOfTurn,
];
