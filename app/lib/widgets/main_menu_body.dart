// Main-menu body layout widgets, split out from `main_menu.dart` to keep the
// host file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`.

part of 'main_menu.dart';

/// Dark editorial-monocle logo region for the `pixelArt` main-menu variant.
///
/// Renders, top-to-bottom: the eyebrow tagline (small-caps `--muted`), the
/// [CtCompassRose] emblem, and a title row composed of
/// `[CtFleurDeLisOrnament] — title text — [CtFleurDeLisOrnament]`. Mirrors
/// `SPEC/ui/main-menu.md` § Logo region.
class _PixelArtLogoRegion extends StatelessWidget {
  const _PixelArtLogoRegion({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? eyebrowStyle = theme.textTheme.labelSmall?.copyWith(
      color: EditorialMonoclePalette.muted,
      letterSpacing: 2.5,
      fontFamily: editorialMonocleDisplayFontFamily,
    );
    final TextStyle? titleStyle = theme.textTheme.headlineMedium?.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: 0.08,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.mainMenu_eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: eyebrowStyle,
        ),
        const SizedBox(height: 16),
        const CtCompassRose(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CtFleurDeLisOrnament(),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const CtFleurDeLisOrnament(),
          ],
        ),
      ],
    );
  }
}

class _MainMenuBody extends StatelessWidget {
  const _MainMenuBody({
    required this.variant,
    required this.showAfterVictorySubtitle,
    required this.loadGameEnabled,
    required this.resumeGameVisible,
    required this.version,
    required this.onNewGame,
    required this.onResumeGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
    required this.logoBuilder,
  });

  final MainMenuVariant variant;
  final bool showAfterVictorySubtitle;
  final bool loadGameEnabled;
  final bool resumeGameVisible;
  final String version;
  final VoidCallback onNewGame;
  final VoidCallback? onResumeGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final Widget Function(BuildContext context) logoBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow = constraints.maxWidth <= kMainMenuNarrowBreakpoint;
          final EdgeInsets padding = narrow
              ? kMainMenuBodyPaddingNarrow
              : kMainMenuBodyPaddingDefault;
          return Padding(
            key: const Key(kMainMenuBodyPaddingKey),
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: _MainMenuBodyContent(
                    variant: variant,
                    showAfterVictorySubtitle: showAfterVictorySubtitle,
                    loadGameEnabled: loadGameEnabled,
                    resumeGameVisible: resumeGameVisible,
                    narrow: narrow,
                    version: version,
                    onNewGame: onNewGame,
                    onResumeGame: onResumeGame,
                    onLoadGame: onLoadGame,
                    onSettings: onSettings,
                    onQuit: onQuit,
                    logoBuilder: logoBuilder,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MainMenuBodyContent extends StatelessWidget {
  const _MainMenuBodyContent({
    required this.variant,
    required this.showAfterVictorySubtitle,
    required this.loadGameEnabled,
    required this.resumeGameVisible,
    required this.narrow,
    required this.version,
    required this.onNewGame,
    required this.onResumeGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
    required this.logoBuilder,
  });

  final MainMenuVariant variant;
  final bool showAfterVictorySubtitle;
  final bool loadGameEnabled;
  final bool resumeGameVisible;
  final bool narrow;
  final String version;
  final VoidCallback onNewGame;
  final VoidCallback? onResumeGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final Widget Function(BuildContext context) logoBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: _menuChildren(context),
    );
  }

  List<Widget> _menuChildren(BuildContext context) {
    final l10n = appL10n(context);
    final bool isPixelArt = variant == MainMenuVariant.pixelArt;
    final TextStyle? subtitleStyle = isPixelArt
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: EditorialMonoclePalette.muted,
          )
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic);
    return [
      const SizedBox(height: 48),
      logoBuilder(context),
      if (showAfterVictorySubtitle) ...[
        const SizedBox(height: 12),
        Text(
          l10n.mainMenu_subtitleAfterVictory,
          style: subtitleStyle,
          textAlign: TextAlign.center,
        ),
      ],
      if (isPixelArt) ...[
        const SizedBox(height: 24),
        const CtBrassDivider(),
        const SizedBox(height: 24),
      ] else
        const SizedBox(height: 32),
      _buttonsRegion(context),
      const SizedBox(height: 32),
      _MainMenuFooter(
        variant: variant,
        version: version,
        quitLabel: l10n.mainMenu_quit,
        onQuit: onQuit,
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Builds the buttons region (New Game → Settings) for the active variant.
  ///
  /// In the `pixelArt` variant the column of wood-panel buttons is wrapped in
  /// a [_PixelArtButtonsRegion] so left/right ornamental scroll brackets can
  /// flank the panel at `kMainMenuScrollBracketGutter` outside each edge,
  /// painted across the middle `1 - 2 * kMainMenuScrollBracketVerticalInset`
  /// fraction of the region height (`SPEC/ui/main-menu.md` § Buttons region;
  /// mockup `.buttons-region::before` / `::after`). In the `plain` variant
  /// the buttons render as a plain `Column` with no scroll-bracket chrome
  /// per the Variant rendering table.
  Widget _buttonsRegion(BuildContext context) {
    final l10n = appL10n(context);
    final List<Widget> buttons = <Widget>[
      _MenuButton(
        label: l10n.mainMenu_newGame,
        variant: variant,
        narrow: narrow,
        onPressed: onNewGame,
      ),
      if (resumeGameVisible) ...[
        const SizedBox(height: 12),
        _MenuButton(
          label: l10n.mainMenu_resumeGame,
          variant: variant,
          narrow: narrow,
          onPressed: onResumeGame!,
        ),
      ],
      const SizedBox(height: 12),
      _LoadGameButton(
        enabled: loadGameEnabled,
        variant: variant,
        narrow: narrow,
        onPressed: onLoadGame,
      ),
      const SizedBox(height: 12),
      _MenuButton(
        label: l10n.mainMenu_settings,
        variant: variant,
        narrow: narrow,
        onPressed: onSettings,
      ),
    ];
    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
    if (variant == MainMenuVariant.pixelArt) {
      return _PixelArtButtonsRegion(child: column);
    }
    return column;
  }
}
