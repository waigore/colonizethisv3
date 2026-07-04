// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Extracted from catalog_part7.dart to keep part fragments under the
// `repo.part_unit_size` 1000-physical-line ceiling
// (`SPEC/program/repo-lint.md`). Hosts the Player Turn Event Feed Card
// Widgetbook stories (issue #2861 S7 / #2870 S9 narrow + mobile viewport).
part of 'catalog.dart';

/// Player turn event feed card stories.
/// SPEC/ui/player-turn-event-feed.md. Issue #2861 S7 + S12 story (10)
/// news feed open / closed. The closed variant just renders the toggle
/// (already covered by `Game Tab Bar` stories), so this folder focuses on
/// the floating card surface itself: populated and empty states.
List<WidgetbookNode> get playerTurnEventFeedCardDirectories => [
  WidgetbookFolder(
    name: 'Player Turn Event Feed Card',
    children: [
      WidgetbookUseCase(
        name: 'Populated — three entries (top entry tappable)',
        builder: (context) => _playerTurnEventFeedCardStoryFrame(
          child: PlayerTurnEventFeedCard(
            entries: [
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'Castile completed Castle in Lisbon.',
                onTap: () {},
              ),
              const PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'England declared war on France.',
              ),
              const PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'New trade route established: Lisbon ↔ Bordeaux.',
              ),
            ],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Empty — no events this turn',
        builder: (context) => _playerTurnEventFeedCardStoryFrame(
          child: const PlayerTurnEventFeedCard(
            entries: [],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport',
        builder: (context) => mobileViewport(
          context,
          _playerTurnEventFeedCardNarrowStoryFrame(
            viewportWidth: 360,
            child: const PlayerTurnEventFeedCard(
              entries: [
                PlayerTurnEventFeedEntry(
                  // ignore: avoid_hardcoded_strings_in_widgets
                  text: 'Castile completed Castle in Lisbon.',
                ),
                PlayerTurnEventFeedEntry(
                  // ignore: avoid_hardcoded_strings_in_widgets
                  text: 'England declared war on France.',
                ),
              ],
              // ignore: avoid_hardcoded_strings_in_widgets
              emptyLabel: 'No events this turn.',
              narrow: true,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (360 dp) — populated, clamp(180, 50vw, 260)',
        builder: (context) => _playerTurnEventFeedCardNarrowStoryFrame(
          viewportWidth: 360,
          child: const PlayerTurnEventFeedCard(
            entries: [
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'Castile completed Castle in Lisbon.',
              ),
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'England declared war on France.',
              ),
            ],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
            narrow: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (460 dp) — populated, 50vw mid-range',
        builder: (context) => _playerTurnEventFeedCardNarrowStoryFrame(
          viewportWidth: 460,
          child: const PlayerTurnEventFeedCard(
            entries: [
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'Castile completed Castle in Lisbon.',
              ),
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'England declared war on France.',
              ),
              PlayerTurnEventFeedEntry(
                // ignore: avoid_hardcoded_strings_in_widgets
                text: 'New trade route established: Lisbon ↔ Bordeaux.',
              ),
            ],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
            narrow: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Narrow (599 dp) — empty, clamp upper bound (260 dp)',
        builder: (context) => _playerTurnEventFeedCardNarrowStoryFrame(
          viewportWidth: 599,
          child: const PlayerTurnEventFeedCard(
            entries: [],
            // ignore: avoid_hardcoded_strings_in_widgets
            emptyLabel: 'No events this turn.',
            narrow: true,
          ),
        ),
      ),
    ],
  ),
];

/// News feed card frame: float the card against a representative dark map
/// background scrim and keep the wide-shell width so the chrome reads the
/// same way it does pinned to the in-game map stack.
MaterialApp _playerTurnEventFeedCardStoryFrame({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: EditorialMonoclePalette.bgDeep,
      body: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

/// Narrow-viewport news feed card frame: clamps the visible canvas to a
/// representative narrow viewport width via `MediaQuery.size`, anchors
/// the card top-right (matching the production stack placement on
/// narrow), and forwards the editorial-monocle theme so the chrome
/// reads identically to the wide story (issue #2870 S3 / Req 11; SPEC
/// `SPEC/ui/player-turn-event-feed.md` § Card chrome — narrow layout).
MaterialApp _playerTurnEventFeedCardNarrowStoryFrame({
  required double viewportWidth,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: Size(viewportWidth, 640)),
      child: Scaffold(
        backgroundColor: EditorialMonoclePalette.bgDeep,
        body: SizedBox(
          width: viewportWidth,
          height: 640,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
