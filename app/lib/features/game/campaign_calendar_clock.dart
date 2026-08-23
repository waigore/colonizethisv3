import 'package:colonizethis_models/colonizethis_models.dart';

/// Live campaign calendar remaining copy for `GAME70001` and the race chip.
///
/// SPEC: `SPEC/ui/victory-panel.md`, `SPEC/ui/components/old-world-race-chip.md`,
/// `SPEC/game/turn-time-mapping.md` § Campaign calendar cap. Refs #4597.
enum CampaignCalendarClockKind {
  remaining,
  lastYear,
  omitCountdown,
  noHaltOnMapping,
}

class CampaignCalendarClock {
  const CampaignCalendarClock({
    required this.kind,
    required this.currentYear,
    required this.lastCampaignYear,
    required this.remainingYears,
    required this.remainingTurns,
  });

  final CampaignCalendarClockKind kind;
  final int currentYear;
  final int lastCampaignYear;
  final int remainingYears;
  final int remainingTurns;

  bool get showsRemainingCountdown =>
      kind == CampaignCalendarClockKind.remaining;

  static CampaignCalendarClock fromGame(Game game) {
    final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
    final turn = game.worldState.turnState.turnNumber;
    final currentYear = mapping.yearAtTurn(turn);
    const lastYear = TurnTimeMapping.campaignCalendarStopStartYear;
    final capTurn = mapping.turnNumberForStartCalendarYear(lastYear);

    if (game.infiniteMode ||
        game.calendarCampaignHalted ||
        game.victory != null) {
      return CampaignCalendarClock(
        kind: CampaignCalendarClockKind.omitCountdown,
        currentYear: currentYear,
        lastCampaignYear: lastYear,
        remainingYears: 0,
        remainingTurns: 0,
      );
    }
    if (capTurn == null) {
      return CampaignCalendarClock(
        kind: CampaignCalendarClockKind.noHaltOnMapping,
        currentYear: currentYear,
        lastCampaignYear: lastYear,
        remainingYears: 0,
        remainingTurns: 0,
      );
    }
    final remainingTurns = capTurn - turn;
    if (remainingTurns <= 0) {
      return const CampaignCalendarClock(
        kind: CampaignCalendarClockKind.lastYear,
        currentYear: lastYear,
        lastCampaignYear: lastYear,
        remainingYears: 0,
        remainingTurns: 0,
      );
    }
    final remainingYears = lastYear - currentYear;
    return CampaignCalendarClock(
      kind: CampaignCalendarClockKind.remaining,
      currentYear: currentYear,
      lastCampaignYear: lastYear,
      remainingYears: remainingYears < 0 ? 0 : remainingYears,
      remainingTurns: remainingTurns,
    );
  }
}
