part of 'game_side_menu.dart';

/// Slide-out hamburger menu: **Game Parameters** (read-only) and **Debug log**.
/// Empire actions use [GameMapEmpireLeftRail]. SPEC/ui/in-game-shell-narrow.md
/// and SPEC/ui/game-side-menu.md (§ Dark-theme chrome for the colour
/// contract of the icons, labels, and the close (×) glyph).
class GameSideMenu extends ConsumerWidget {
  const GameSideMenu({
    required this.sideMenuOpen,
    required this.onClose,
    super.key,
  });

  static const screenId = UiScreenIds.gameSideMenu;

  final bool sideMenuOpen;
  final VoidCallback onClose;

  static const double _kSideMenuWidth = 240;

  /// Side length of the leading Material icon glyphs in each menu row.
  static const double _kRowIconSize = 20;

  /// Per-`HorizontalDragUpdate` `details.delta.dx` threshold (in logical
  /// pixels, **inclusive lower bound is exclusive**) that triggers
  /// [onClose] on the swipe-to-close gesture.
  ///
  /// `details.delta.dx < kSwipeToCloseDeltaThreshold` (i.e. a left-ward
  /// drag delivering more than 5 logical pixels in a single update) closes
  /// the menu; any right-ward (`> 0`) or stationary (`== 0`) delta is
  /// ignored. SPEC: `SPEC/ui/in-game-shell-narrow.md` § Acceptance criteria
  /// (positive swipe-to-close contract + right-swipe negative regression
  /// guard). Public so the pinning test
  /// (`app/test/game_side_menu_swipe_to_close_test.dart`) references the
  /// same single source as the production gesture handler.
  static const double kSwipeToCloseDeltaThreshold = -5.0;

  void _openGameParameters(BuildContext context, ct_models.Game game) {
    onClose();
    showDialog<void>(
      context: context,
      builder: (ctx) => GameParametersDialog(infiniteMode: game.infiniteMode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    final ct_models.Game? game = ref.watch(currentGameProvider);
    final ThemeData theme = Theme.of(context);
    // Body label colour for Game Parameters / Debug log rows.
    // SPEC: game-side-menu.md § Dark-theme chrome.
    final TextStyle labelStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    // Close (×) glyph colour. Mirrors ProvinceSeaZoneDetailOverlay close
    // control (Refs #2865 PR #2894): muted token because the close button
    // is a secondary affordance (Escape / scrim-tap / drag-left close the
    // menu too).
    final TextStyle closeGlyphStyle =
        (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
          color: EditorialMonoclePalette.muted,
          fontWeight: FontWeight.w700,
        );
    return TweenAnimationBuilder<Offset>(
      key: ValueKey(sideMenuOpen),
      tween: Tween<Offset>(
        begin: Offset(sideMenuOpen ? -1 : 0, 0),
        end: Offset(sideMenuOpen ? 0 : -1, 0),
      ),
      duration: const Duration(milliseconds: 200),
      builder: (context, Offset offset, child) {
        return Positioned(
          left: offset.dx * _kSideMenuWidth,
          top: 0,
          bottom: 0,
          width: _kSideMenuWidth,
          child: child!,
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < kSwipeToCloseDeltaThreshold) onClose();
        },
        child: CtPanel(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CtNinePatchButton(
                    onPressed: onClose,
                    child: Text('×', style: closeGlyphStyle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CtNinePatchButton(
                onPressed: game == null
                    ? null
                    : () => _openGameParameters(context, game),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: _kRowIconSize,
                      color: EditorialMonoclePalette.accentDim,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.gameParameters_menuEntry,
                        style: labelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CtNinePatchButton(
                onPressed: () {
                  onClose();
                  ref
                      .read(appEventBusProvider)
                      .emit(
                        const ct_models.NavigateToRouteEvent(Routes.debugLog),
                      );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      size: _kRowIconSize,
                      color: EditorialMonoclePalette.accentDim,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.debugLog_title,
                        style: labelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
