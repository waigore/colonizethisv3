// coverage:ignore-file
// Dev-only Widgetbook catalog part; Game Tab Bar Old World race chip
// stories (Refs #4451). Split from catalog_game_chrome.dart so that
// fragment stays under the repo-wide 1000 non-comment-line ceiling.
part of 'catalog.dart';

const OldWorldRaceSnapshot _kHumanAheadRace = OldWorldRaceSnapshot(
  focusPlayerId: 'gp1',
  focusCount: 18,
  threshold: 31,
  calendarClock: CampaignCalendarClock(
    kind: CampaignCalendarClockKind.remaining,
    currentYear: 1582,
    lastCampaignYear: 1800,
    remainingYears: 218,
    remainingTurns: 159,
  ),
);

const OldWorldRaceSnapshot _kRivalAheadRace = OldWorldRaceSnapshot(
  focusPlayerId: 'gp1',
  focusCount: 12,
  threshold: 31,
  rivalLeaderName: 'Spain',
  rivalLeaderCount: 20,
);

/// Game Tab Bar Old World race chip use cases. Refs #4451.
List<WidgetbookUseCase> get _oldWorldRaceTabBarStories => [
  WidgetbookUseCase(
    name: 'Old World race — human ahead',
    builder: (context) => _gameTabBarStoryFrame(oldWorldRace: _kHumanAheadRace),
  ),
  WidgetbookUseCase(
    name: 'Old World race — rival ahead',
    builder: (context) => _gameTabBarStoryFrame(oldWorldRace: _kRivalAheadRace),
  ),
  WidgetbookUseCase(
    name: 'Old World race — players bar hidden',
    builder: (context) => _gameTabBarStoryFrame(
      oldWorldRace: _kHumanAheadRace,
      showPlayersBar: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Old World race — 320 dp rival ahead',
    builder: (context) => SizedBox(
      width: 320,
      child: _gameTabBarStoryFrame(
        oldWorldRace: _kRivalAheadRace,
        oldWorldRaceNarrow: true,
        showPlayersBar: false,
      ),
    ),
  ),
  WidgetbookUseCase(
    name: 'Old World race — remaining years tooltip',
    builder: (context) =>
        _gameTabBarStoryFrame(oldWorldRace: _kHumanAheadRace),
  ),
];
