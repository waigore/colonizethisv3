import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/campaign_calendar_clock.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  test('gdd01 turn 42 remaining years and turns (Refs #4597)', () {
    final clock = CampaignCalendarClock.fromGame(
      buildPanelTestGame(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 42),
      ),
    );
    expect(clock.kind, CampaignCalendarClockKind.remaining);
    expect(clock.currentYear, 1582);
    expect(clock.lastCampaignYear, 1800);
    expect(clock.remainingYears, 218);
    expect(clock.remainingTurns, 159);
  });

  test('cap turn is last year with remaining 0', () {
    final clock = CampaignCalendarClock.fromGame(
      buildPanelTestGame(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 201),
      ),
    );
    expect(clock.kind, CampaignCalendarClockKind.lastYear);
    expect(clock.remainingYears, 0);
    expect(clock.remainingTurns, 0);
  });

  test('infinite mode omits countdown', () {
    final clock = CampaignCalendarClock.fromGame(
      buildPanelTestGame(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 42),
      ).copyWith(infiniteMode: true),
    );
    expect(clock.kind, CampaignCalendarClockKind.omitCountdown);
    expect(clock.showsRemainingCountdown, isFalse);
  });

  test('halt and province win omit countdown', () {
    final halted = CampaignCalendarClock.fromGame(
      buildPanelTestGame().copyWith(calendarCampaignHalted: true),
    );
    expect(halted.kind, CampaignCalendarClockKind.omitCountdown);

    final won = CampaignCalendarClock.fromGame(
      buildPanelTestGame().copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'gp1',
          type: VictoryType.military,
          turnNumber: 10,
        ),
      ),
    );
    expect(won.kind, CampaignCalendarClockKind.omitCountdown);
  });

  test('mapping with no 1800 turn does not invent a halt', () {
    final clock = CampaignCalendarClock.fromGame(
      buildPanelTestGame().copyWith(
        turnTimeMapping: const TurnTimeMapping(
          startYear: 1500,
          cutoffYear: 1700,
          yearsPerTurnBeforeCutoff: 2,
          yearsPerTurnAfterCutoff: 3,
        ),
      ),
    );
    expect(clock.kind, CampaignCalendarClockKind.noHaltOnMapping);
  });
}
