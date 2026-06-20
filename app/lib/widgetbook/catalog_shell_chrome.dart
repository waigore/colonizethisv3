// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
//
// Extracted from catalog_part5.dart to keep part fragments under the
// `repo.part_unit_size` 1000-physical-line ceiling
// (`SPEC/program/repo-lint.md`). Hosts:
//
// - The [_CtIconActionStory] dark-theme primitive preview (Refs #2914 §S8)
//   referenced from `ctDarkThemePrimitiveDirectories` in catalog_part5.dart.
// - [_CtScreenShellStory], [_CtPanelWithTopBarStory], and
//   [_CtDarkScaffoldStory] shell-chrome previews (issue #3279 §5/§6).
// - The Next Turn Confirmation (DLG60001) and Game Initializing
//   (SHEL30001) Widgetbook stories introduced by issue #2867 S13.
part of 'catalog.dart';

/// Showcases [CtScreenShell] in both its default (no back button) and
/// `showBackButton: true` modes so reviewers can confirm the 36 px
/// [CtTopBar] chrome + framed body composition under the
/// `editorialMonocle` theme (Refs #2859 R4 / S5). The host inflates the
/// shells inside a `MaterialApp` so [Navigator.maybePop] is valid when the
/// chevron is tapped.
class _CtScreenShellStory extends StatelessWidget {
  const _CtScreenShellStory();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      home: Scaffold(
        backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
        body: Row(
          children: <Widget>[
            Expanded(
              child: CtScreenShell(
                // ignore: avoid_hardcoded_strings_in_widgets
                title: 'Default (no back button)',
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'CtTopBar omits the leading CtBackButton when '
                      'showBackButton is false.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CtScreenShell(
                // ignore: avoid_hardcoded_strings_in_widgets
                title: 'With back button',
                showBackButton: true,
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'CtTopBar renders the leading CtBackButton chevron '
                      'and wires it through to Navigator.maybePop().',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Showcases [CtPanelWithTopBar] — the shared `CtPanel` + `Column` +
/// top-bar skeleton extracted from [CtScreenShell] and `UnitsPanelShell`
/// (issue #3279 §5). Renders one variant with a [CtTopBar] and one with
/// `topBar: null` so reviewers can confirm the optional title-band slot.
/// SPEC/ui/components/ct-panel-with-top-bar.md.
class _CtPanelWithTopBarStory extends StatelessWidget {
  const _CtPanelWithTopBarStory();

  @override
  Widget build(BuildContext context) {
    return CtDarkPrimitiveScaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Expanded(
            child: CtPanelWithTopBar(
              mainAxisSize: MainAxisSize.min,
              // ignore: avoid_hardcoded_strings_in_widgets
              topBar: CtTopBar(title: 'With top bar', showBackButton: false),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    // ignore: avoid_hardcoded_strings_in_widgets
                    'Inner CtPanel + Column(stretch) skeleton with a '
                    'CtTopBar first child.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: CtPanelWithTopBar(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    // ignore: avoid_hardcoded_strings_in_widgets
                    'topBar: null omits the title band; only children are '
                    'mounted inside the panel.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Showcases [CtDarkScaffold] — the reusable dark-chrome screen wrapper
/// (`Scaffold` + `SafeArea` + `Column(topBar + Expanded body)`) promoted
/// from the private `_DarkChromeShell` in [CtGameFeatureScreenShell]
/// (issue #3279 §6). SPEC/ui/components/ct-dark-scaffold.md.
class _CtDarkScaffoldStory extends StatelessWidget {
  const _CtDarkScaffoldStory();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      home: const CtDarkScaffold(
        // ignore: avoid_hardcoded_strings_in_widgets
        topBar: CtTopBar(title: 'CtDarkScaffold', showBackButton: false),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              // ignore: avoid_hardcoded_strings_in_widgets
              'Top bar stacked above an Expanded body inside a SafeArea; '
              'background defaults to colorScheme.surface.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Refs #2914 §S8 — preview the [CtIconAction] primitive that replaces the
/// banned Material `IconButton` chrome across the in-game feature tree.
/// Renders the three families of call sites (locate, build improvement,
/// menu) so a reviewer can hover/tap each and see the idle / hover /
/// pressed / disabled colour transitions wired through
/// [EditorialMonoclePalette].
///
/// Lives in its own part fragment (not catalog_part5.dart) so the editorial
/// monocle primitives part stays under the 1000-line `repo.part_unit_size`
/// cap that the repo lint enforces.
class _CtIconActionStory extends StatefulWidget {
  const _CtIconActionStory();

  @override
  State<_CtIconActionStory> createState() => _CtIconActionStoryState();
}

class _CtIconActionStoryState extends State<_CtIconActionStory> {
  int _locateTaps = 0;
  int _buildTaps = 0;
  int _menuTaps = 0;

  @override
  Widget build(BuildContext context) {
    return CtDarkPrimitiveScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Locate (tooltip + default 18 dp glyph)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CtIconAction(
                icon: Icons.my_location,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Locate',
                onPressed: () => setState(() => _locateTaps++),
              ),
              const SizedBox(width: 12),
              const CtIconAction(
                icon: Icons.my_location,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Locate (disabled)',
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Build / explore / prospect (province overlay tile actions)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CtIconAction(
                icon: Icons.handyman,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Build improvement',
                onPressed: () => setState(() => _buildTaps++),
              ),
              const SizedBox(width: 12),
              CtIconAction(
                icon: Icons.explore,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Explore with explorer',
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              CtIconAction(
                icon: Icons.travel_explore,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Prospect with explorer',
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              CtIconAction(
                icon: Icons.handyman,
                enabled: false,
                // ignore: avoid_hardcoded_strings_in_widgets
                tooltip: 'Build improvement (disabled)',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'Menu (game screen top-left, 24 dp glyph)',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          CtIconAction(
            icon: Icons.menu,
            iconSize: 24,
            // ignore: avoid_hardcoded_strings_in_widgets
            tooltip: 'Pause menu',
            onPressed: () => setState(() => _menuTaps++),
          ),
          const SizedBox(height: 16),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            'taps — locate: $_locateTaps · build: $_buildTaps · '
            'menu: $_menuTaps',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Renders [NextTurnConfirmationDialog] (DLG60001) inside a `MaterialApp`
/// using the editorial-monocle dark theme so the catalog can preview the
/// dialog without driving the `showNextTurnConfirmationDialog` flow.
///
/// SPEC: `SPEC/ui/next-turn-confirmation.md` § Dark-theme styling — DLG60001
/// must use `CtDialogShell`, `--accent` title text, `--fg` body text, and
/// both actions rendered with `CtNinePatchButton`. Story exercises both the
/// pre-resolution baseline turn number and a mid-game turn number to cover
/// the body interpolation contract.
class _NextTurnConfirmationDialogStoryHost extends StatelessWidget {
  const _NextTurnConfirmationDialogStoryHost({required this.currentTurn});

  final int currentTurn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: EditorialMonoclePalette.dialogScrim,
        body: Center(
          child: NextTurnConfirmationDialog(currentTurn: currentTurn),
        ),
      ),
    );
  }
}

/// Next turn confirmation dialog stories (DLG60001).
/// SPEC/ui/next-turn-confirmation.md.
List<WidgetbookNode> get nextTurnConfirmationDialogDirectories => [
  WidgetbookFolder(
    name: 'Next Turn Confirmation',
    children: [
      WidgetbookUseCase(
        name: 'Default — turn 1',
        builder: (context) =>
            const _NextTurnConfirmationDialogStoryHost(currentTurn: 1),
      ),
      WidgetbookUseCase(
        name: 'Mid-game — turn 42',
        builder: (context) =>
            const _NextTurnConfirmationDialogStoryHost(currentTurn: 42),
      ),
    ],
  ),
];

/// Renders the [NewGameSetupProgressView] (SHEL30001) inside a `MaterialApp`
/// using the editorial-monocle dark theme so the catalog can preview every
/// phase label and the 48 px `--accent` spinner without running the
/// `GameService` setup pipeline.
///
/// SPEC: `SPEC/ui/game-initializing.md` § Dark-theme visual contract — the
/// progress dialog renders a 48 px circular indicator whose arc resolves
/// from the `--accent` palette token (#2867 R32) and a phase label that
/// maps 1:1 to `GameService.newGameSetupProgressStepCount` indices `0..4`
/// (#2867 R33).
class _GameInitializingProgressStoryHost extends StatelessWidget {
  const _GameInitializingProgressStoryHost({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: EditorialMonoclePalette.dialogScrim,
        body: Center(
          child: NewGameSetupProgressView(stepIndex: stepIndex),
        ),
      ),
    );
  }
}

/// Renders [NewGameErrorCard] inside the dark `CtDialogShell` chrome that
/// the production `_showNewGameErrorDialog` flow wraps it in, so reviewers
/// can preview the 1 px `--danger` error frame, the `Retry` / `Close`
/// `CtNinePatchButton` row, and the localised title without driving an
/// actual setup failure.
///
/// SPEC: `SPEC/ui/game-initializing.md` § Failure and retry — the error
/// dialog content card paints a 1 px border colored `--danger` on all four
/// sides (#2867 R34).
class _GameInitializingErrorStoryHost extends StatelessWidget {
  const _GameInitializingErrorStoryHost();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: EditorialMonoclePalette.dialogScrim,
        body: Builder(
          builder: (ctx) {
            final l10n = appL10n(ctx);
            return Center(
              child: CtDialogShell(
                child: NewGameErrorCard(
                  title: l10n.shell_newGameError_title,
                  message:
                      // ignore: avoid_hardcoded_strings_in_widgets
                      'StateError: provincial assigner failed to '
                      'lock the requested coastal seed (Widgetbook preview)',
                  closeLabel: l10n.common_close,
                  retryLabel: l10n.shell_newGameError_retry,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Game initializing stories (SHEL30001) covering the progress dialog
/// across every coarse phase plus the failure-state error card.
/// SPEC/ui/game-initializing.md.
List<WidgetbookNode> get gameInitializingDirectories => [
  WidgetbookFolder(
    name: 'Game Initializing',
    children: [
      WidgetbookUseCase(
        name: 'Progress — phase 0 (Old World)',
        builder: (context) =>
            const _GameInitializingProgressStoryHost(stepIndex: 0),
      ),
      WidgetbookUseCase(
        name: 'Progress — phase 1 (New World)',
        builder: (context) =>
            const _GameInitializingProgressStoryHost(stepIndex: 1),
      ),
      WidgetbookUseCase(
        name: 'Progress — phase 2 (Warp linking)',
        builder: (context) =>
            const _GameInitializingProgressStoryHost(stepIndex: 2),
      ),
      WidgetbookUseCase(
        name: 'Progress — phase 3 (Building world)',
        builder: (context) =>
            const _GameInitializingProgressStoryHost(stepIndex: 3),
      ),
      WidgetbookUseCase(
        name: 'Progress — phase 4 (Saving)',
        builder: (context) =>
            const _GameInitializingProgressStoryHost(stepIndex: 4),
      ),
      WidgetbookUseCase(
        name: 'Error — danger-bordered retry card',
        builder: (context) => const _GameInitializingErrorStoryHost(),
      ),
    ],
  ),
];
