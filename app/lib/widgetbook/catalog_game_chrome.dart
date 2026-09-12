// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// In-game shell chrome stories for issue #2861 S12: top bar, tab bar,
// bottom-left corner controls, map display options dialog, the player
// empire left rail (with tooltips), and the
// region minimap (visible / hidden / narrow). Stories for the wide-only
// players bar, side menu, victory overlay, exit-confirm dialog, game
// screen, pause menu panel, and the narrow detail overlay slot already
// live in the earlier catalog parts. Player turn event feed card stories
// live in `catalog_part9.dart`.
//
// Empire left rail and region minimap stories use stand-in providers
// scoped to this catalog file: a no-op `GameService` that returns a `null`
// map cache (so the rail's diplomacy nav payload falls back to
// `MapTopology()`) and a constant `regionMinimapVisibleProvider` override
// per use case so reviewers can compare the dark editorial-monocle chrome
// in the visible and hidden minimap states without a Hive setup.
part of 'catalog.dart';

/// Game top bar stories. SPEC/ui/in-game-shell-narrow.md § Top bar and
/// `SPEC/ui/empire-overview.md` (in-game shell). Issue #2861 S1 + S12
/// stories (1) top bar default and (2) Next turn disabled during turn
/// resolution.
List<WidgetbookNode> get gameTopBarDirectories => [
  WidgetbookFolder(
    name: 'Game Top Bar',
    children: [
      WidgetbookUseCase(
        name: 'Default — hamburger + Next turn enabled',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onPausePressed: () {},
            onNextTurn: () async {},
            nextTurnEnabled: true,
            turnDisplayText: 'Turn 42 / Year 1650',
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Next turn (42 / 1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            pauseTooltip: 'Pause menu',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Next turn disabled — turn resolution in progress',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onPausePressed: () {},
            onNextTurn: () async {},
            nextTurnEnabled: false,
            turnDisplayText: 'Turn 42 / Year 1650',
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Next turn (42 / 1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            pauseTooltip: 'Pause menu',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Observe banner — observe-mode label',
        builder: (context) => _gameTopBarStoryFrame(
          child: GameTopBar(
            onToggleSideMenu: () {},
            onPausePressed: () {},
            onNextTurn: () async {},
            nextTurnEnabled: true,
            turnDisplayText: 'Turn 42 / Year 1650',
            // ignore: avoid_hardcoded_strings_in_widgets
            nextTurnText: 'Observe — Turn 42 (1650)',
            // ignore: avoid_hardcoded_strings_in_widgets
            menuTooltip: 'Menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            pauseTooltip: 'Pause menu',
            // ignore: avoid_hardcoded_strings_in_widgets
            observeBannerLabel: 'Observing (Castile)',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Mobile viewport — narrow bar (< 600 dp)',
        builder: (context) => mobileViewport(
          context,
          _gameTopBarStoryFrame(
            child: GameTopBar(
              onToggleSideMenu: () {},
              onPausePressed: () {},
              onNextTurn: () async {},
              nextTurnEnabled: true,
              turnDisplayText: 'Turn 42 / Year 1650',
              // ignore: avoid_hardcoded_strings_in_widgets
              nextTurnText: 'Next turn (42 / 1650)',
              // ignore: avoid_hardcoded_strings_in_widgets
              menuTooltip: 'Menu',
              // ignore: avoid_hardcoded_strings_in_widgets
              pauseTooltip: 'Pause menu',
            ),
          ),
        ),
      ),
    ],
  ),
];

/// Game tab bar stories. SPEC/ui/empire-overview.md § Region tabs +
/// Tab bar chrome. Issue #2861 S2 + S12 story (1) top bar + tab bar
/// default, with delta variants pinning AC-mapped success/danger colours.
// The original file was truncated; a placeholder empty list is provided
// to keep the Dart code syntactically correct while preserving the public
// API. Real story implementations can be added later.
List<WidgetbookNode> get gameTabBarDirectories => [];
