// At-current-funding finish-time estimate for GAME40001 slot cards
// (Refs #4511). Pure helper: remaining RP ÷ this-turn RP, plus optional
// calendar year with campaign-cap suppression.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview (Finish-time line);
// SPEC/game/turn-time-mapping.md § Campaign calendar cap.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_slot_preview.dart';

/// Turns remaining and remaining RP for a spending research seat.
class ResearchFinishEstimate {
  const ResearchFinishEstimate({
    required this.remainingRp,
    required this.turnsRemaining,
    required this.completesNextTurn,
  });

  /// `cost − committedProgress` (strictly positive when this object exists).
  final int remainingRp;

  /// `ceil(remainingRp / anticipatedRpPerTurn)`; `1` when [completesNextTurn].
  final int turnsRemaining;

  /// True when remaining RP will be covered by this turn's anticipated RP.
  final bool completesNextTurn;
}

/// Calendar context for the optional year suffix on the finish-time line.
class ResearchFinishCalendar {
  const ResearchFinishCalendar({
    required this.currentTurn,
    required this.mapping,
    required this.infiniteMode,
  });

  factory ResearchFinishCalendar.fromGame(Game game) {
    return ResearchFinishCalendar(
      currentTurn: game.worldState.turnState.turnNumber,
      mapping: game.turnTimeMapping ?? TurnTimeMapping.gdd01,
      infiniteMode: game.infiniteMode,
    );
  }

  final int currentTurn;
  final TurnTimeMapping mapping;
  final bool infiniteMode;
}

/// Returns a finish estimate when the seat will apply RP and remaining RP
/// is still positive; otherwise `null` (None / blocked / already complete).
ResearchFinishEstimate? researchFinishEstimate(
  ResearchSlotTurnPreview preview,
) {
  final int anticipated = preview.anticipatedRpPerTurn;
  if (anticipated <= 0) {
    return null;
  }
  final int remaining = preview.cost - preview.committedProgress;
  if (remaining <= 0) {
    return null;
  }
  final int turns = (remaining + anticipated - 1) ~/ anticipated;
  return ResearchFinishEstimate(
    remainingRp: remaining,
    turnsRemaining: turns,
    completesNextTurn: remaining <= anticipated,
  );
}

/// Calendar year at the estimated finish turn, or `null` when suppressed.
///
/// Suppresses the year when the campaign calendar cap applies
/// (`yearAtTurn(T) == 1800` → `T = 201` under `gdd01`) and the finish turn
/// is after that cap, unless [calendar.infiniteMode] is true.
int? researchFinishCalendarYear({
  required ResearchFinishEstimate estimate,
  required ResearchFinishCalendar calendar,
}) {
  final int turn = calendar.currentTurn < 1 ? 1 : calendar.currentTurn;
  final int finishTurn = turn + estimate.turnsRemaining;
  if (!calendar.infiniteMode) {
    final int? capTurn = calendar.mapping.turnNumberForStartCalendarYear(
      TurnTimeMapping.campaignCalendarStopStartYear,
    );
    if (capTurn != null && finishTurn > capTurn) {
      return null;
    }
  }
  return calendar.mapping.yearAtTurn(finishTurn);
}
