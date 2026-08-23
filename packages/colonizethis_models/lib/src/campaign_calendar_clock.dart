import 'game.dart';
import 'turn_time_mapping.dart';

/// Live remaining calendar years/turns until the campaign cap.
///
/// SPEC: `SPEC/game/turn-time-mapping.md` § Campaign calendar cap,
/// `SPEC/ui/victory-panel.md`. Refs #4597.
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

    CampaignCalendarClock clock(
      CampaignCalendarClockKind kind, {
      int year = 0,
      int remainingTurns = 0,
      int remainingYears = 0,
    }) => CampaignCalendarClock(
      kind: kind,
      currentYear: year,
      lastCampaignYear: lastYear,
      remainingYears: remainingYears,
      remainingTurns: remainingTurns,
    );

    if (game.infiniteMode ||
        game.calendarCampaignHalted ||
        game.victory != null) {
      return clock(CampaignCalendarClockKind.omitCountdown, year: currentYear);
    }
    if (capTurn == null) {
      return clock(
        CampaignCalendarClockKind.noHaltOnMapping,
        year: currentYear,
      );
    }
    final remainingTurns = capTurn - turn;
    if (remainingTurns <= 0) {
      return clock(CampaignCalendarClockKind.lastYear, year: lastYear);
    }
    final remainingYears = lastYear - currentYear;
    return clock(
      CampaignCalendarClockKind.remaining,
      year: currentYear,
      remainingTurns: remainingTurns,
      remainingYears: remainingYears < 0 ? 0 : remainingYears,
    );
  }
}
