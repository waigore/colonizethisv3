import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import '../config/editorial_monocle_palette.dart';
import '../config/themes.dart';
import '../config/ui_screen_ids.dart';
import 'ct_brass_divider.dart';
import 'ct_compass_rose.dart';
import 'ct_fleur_de_lis_ornament.dart';
import 'ct_gradients.dart';
import 'ct_main_menu_collage.dart';
import 'ct_nine_patch_button.dart';

/// Narrow-viewport breakpoint for the main menu in logical pixels.
///
/// At or below this width the menu container compacts its horizontal padding
/// and the `pixelArt` variant button labels reduce `letter-spacing` per
/// `SPEC/ui/mockups/SHEL10002-main-menu.html` `@media (max-width: 430px)` and
/// `SPEC/ui/main-menu.md` § Responsive rules.
const double kMainMenuNarrowBreakpoint = 430;

/// Letter-spacing (logical pixels) applied to `pixelArt` variant menu-button
/// labels at viewports wider than [kMainMenuNarrowBreakpoint]. Mirrors the
/// mockup `.menu-btn { letter-spacing: 0.08em }` default at the ~16dp font
/// size used by the wood-panel button text style.
const double kMainMenuButtonLetterSpacingDefault = 1.2;

/// Letter-spacing (logical pixels) applied to `pixelArt` variant menu-button
/// labels at viewports `≤ kMainMenuNarrowBreakpoint`. Mirrors the mockup
/// `.menu-btn { letter-spacing: 0.04em }` narrow override.
const double kMainMenuButtonLetterSpacingNarrow = 0.6;

/// Menu container padding at viewports `> kMainMenuNarrowBreakpoint`.
/// Default desktop / wide layout.
const EdgeInsets kMainMenuBodyPaddingDefault = EdgeInsets.symmetric(
  horizontal: CtSpacing.xxl,
);

/// Menu container padding at viewports `≤ kMainMenuNarrowBreakpoint`.
/// Compacts horizontal padding and adds explicit vertical padding to mirror
/// the mockup `.menu-container { padding: 24px 12px; }` narrow override.
const EdgeInsets kMainMenuBodyPaddingNarrow = EdgeInsets.symmetric(
  horizontal: CtSpacing.ml,
  vertical: CtSpacing.xxl,
);

/// Stable `Key` value for the menu body `Padding` widget that owns the
/// responsive padding resolution. Used by widget tests to assert the
/// padding flips between [kMainMenuBodyPaddingDefault] and
/// [kMainMenuBodyPaddingNarrow] at [kMainMenuNarrowBreakpoint].
const String kMainMenuBodyPaddingKey = 'main_menu_body_padding';

/// Stable `Key` value for the `pixelArt` variant footer Quit button. The
/// secondary, smaller, border-only chip per `SPEC/ui/main-menu.md` §
/// Variant rendering — Quit button row and `SPEC/ui/mockups/SHEL10002-main-menu.html`
/// `.quit-btn`. Used by widget tests to assert chrome differs from the
/// wood-panel primary buttons (no brass corner brackets, smaller min-height,
/// `--muted` foreground).
const String kMainMenuFooterQuitKey = 'main_menu_footer_quit';

/// Minimum tap-target height for the `pixelArt` variant footer Quit button.
/// Mirrors the mockup `.quit-btn { min-height: 44px }` rule and keeps the
/// button just above the 44 dp accessibility threshold; smaller than the
/// 48 dp primary wood-panel buttons per AC 9.
const double kMainMenuFooterQuitMinHeight = 44;

/// Stable `Key` value for the left ornamental scroll bracket flanking the
/// `pixelArt` buttons region. Mirrors the mockup
/// `SPEC/ui/mockups/SHEL10002-main-menu.html` `.buttons-region::before` rule
/// and the `SPEC/ui/main-menu.md` § Buttons region scroll-bracket entry.
/// Widget tests assert presence under `pixelArt` and absence under `plain`.
const String kMainMenuScrollBracketLeftKey = 'main_menu_scroll_bracket_left';

/// Stable `Key` value for the right ornamental scroll bracket flanking the
/// `pixelArt` buttons region. Mirror of [kMainMenuScrollBracketLeftKey]; see
/// the same SPEC sections for the mockup `.buttons-region::after` mapping.
const String kMainMenuScrollBracketRightKey = 'main_menu_scroll_bracket_right';

/// Width (logical pixels) of each ornamental scroll-bracket bar flanking the
/// `pixelArt` buttons region. Mirrors mockup `.buttons-region::before { width:
/// 4px }`.
const double kMainMenuScrollBracketWidth = 4;

/// Horizontal gutter (logical pixels) by which each scroll bracket is offset
/// outward from the corresponding edge of the `pixelArt` buttons region.
/// Mirrors mockup `.buttons-region::before { left: -10px }` (and `::after {
/// right: -10px }`).
const double kMainMenuScrollBracketGutter = 10;

/// Vertical fraction of the buttons region height inset above and below the
/// scroll-bracket bar. Mirrors mockup `.buttons-region::before { top: 10%;
/// bottom: 10% }`, so the bar paints across the middle 80 % of the buttons
/// region height.
const double kMainMenuScrollBracketVerticalInset = 0.10;

/// Combined fill opacity applied to each scroll bracket (bar + ornamental
/// dots). Mirrors mockup `.buttons-region::before { opacity: 0.45 }` so the
/// bracket reads as a faint chrome flourish, not a structural rule.
const double kMainMenuScrollBracketOpacity = 0.45;

/// Visual variant of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuVariant {
  /// Theme-scaffold only fallback: standard Flutter widgets with the
  /// running app theme; no SVG collage, no compass rose, no fleur-de-lis,
  /// no brass divider, no scroll brackets, no wood-panel chrome. See
  /// `SPEC/ui/main-menu.md` § Variant rendering.
  plain,

  /// Dark editorial-monocle layout per
  /// `SPEC/ui/mockups/SHEL10002-main-menu.html`: [CtMainMenuCollage]
  /// background, [CtCompassRose] above the title row, title flanked by two
  /// [CtFleurDeLisOrnament]s, [CtBrassDivider] between the logo region and
  /// the buttons region. Rendered under [AppThemes.editorialMonocle] and
  /// [EditorialMonoclePalette] tokens.
  pixelArt,
}

/// Content state of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuState {
  /// Default: no subtitle; Load Game enabled if [noSaves] is not used.
  default_,

  /// After victory: show subtitle "Congratulations, you won your last game."
  afterVictory,

  /// No saves: Load Game disabled with explanatory helper text/tooltip.
  noSaves,
}

/// Main menu screen. Full-screen layout per UXD 03a wireframes.
/// Callbacks are supplied by the shell; widget does not perform routing.
/// Min 44dp touch targets per UXD 03.
class CtMainMenu extends StatelessWidget {
  const CtMainMenu({
    super.key,
    required this.variant,
    required this.state,
    required this.version,
    required this.onNewGame,
    this.resumeGameVisible = false,
    this.onResumeGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
  }) : assert(
         !resumeGameVisible || onResumeGame != null,
         'onResumeGame is required when resumeGameVisible is true',
       );

  /// SPEC/ui/main-menu.md — [UiScreenIds.mainMenu].
  static const screenId = UiScreenIds.mainMenu;

  final MainMenuVariant variant;
  final MainMenuState state;
  final String version;
  final VoidCallback onNewGame;
  final bool resumeGameVisible;
  final VoidCallback? onResumeGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  bool get _loadGameEnabled => state != MainMenuState.noSaves;
  bool get _showAfterVictorySubtitle => state == MainMenuState.afterVictory;

  @override
  Widget build(BuildContext context) {
    final content = _MainMenuBody(
      variant: variant,
      showAfterVictorySubtitle: _showAfterVictorySubtitle,
      loadGameEnabled: _loadGameEnabled,
      resumeGameVisible: resumeGameVisible,
      version: version,
      onNewGame: onNewGame,
      onResumeGame: onResumeGame,
      onLoadGame: onLoadGame,
      onSettings: onSettings,
      onQuit: onQuit,
      logoBuilder: _buildLogo,
    );

    if (variant == MainMenuVariant.pixelArt) {
      return Theme(
        data: AppThemes.editorialMonocle,
        child: Scaffold(
          backgroundColor: EditorialMonoclePalette.bg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: CtMainMenuCollage()),
              content,
            ],
          ),
        ),
      );
    }

    return Scaffold(body: content);
  }

  Widget _buildLogo(BuildContext context) {
    if (variant == MainMenuVariant.plain) {
      return Text(
        appL10n(context).mainMenu_title,
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      );
    }
    return _PixelArtLogoRegion(title: appL10n(context).mainMenu_title);
  }
}

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

/// Footer region for both variants. Renders the version text above a Quit
/// control; in the `pixelArt` variant the Quit control is the smaller,
/// `--muted`, border-only chip per `SPEC/ui/main-menu.md` § Variant
/// rendering (AC 9), while the `plain` variant continues to use a regular
/// [CtNinePatchButton] for backward compatibility.
class _MainMenuFooter extends StatelessWidget {
  const _MainMenuFooter({
    required this.variant,
    required this.version,
    required this.quitLabel,
    required this.onQuit,
  });

  final MainMenuVariant variant;
  final String version;
  final String quitLabel;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    if (variant == MainMenuVariant.pixelArt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PixelArtFooterVersion(version: version),
          const SizedBox(height: 12),
          _FooterQuitButton(label: quitLabel, onPressed: onQuit),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(version, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: CtNinePatchButton(
            onPressed: onQuit,
            child: Text(quitLabel),
          ),
        ),
      ],
    );
  }
}

/// Monospace `--muted` version line for the `pixelArt` variant footer.
/// Mirrors mockup `.version { font-family: var(--font-mono); color:
/// var(--muted); letter-spacing: 0.08em; text-transform: uppercase; }` and
/// realises the `SPEC/ui/main-menu.md` § Variant rendering row "Footer
/// version text — Monospace (`--font-mono`), `--muted` token from #2858".
class _PixelArtFooterVersion extends StatelessWidget {
  const _PixelArtFooterVersion({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final TextStyle? baseStyle = Theme.of(context).textTheme.bodySmall;
    return Text(
      version.toUpperCase(),
      style: (baseStyle ?? const TextStyle()).copyWith(
        color: EditorialMonoclePalette.muted,
        fontFamily: 'monospace',
        fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
        // Mirrors mockup `.version { letter-spacing: 0.08em }` at the 12 px
        // text size (~0.96 px). Kept distinct from the wood-panel button
        // label letter-spacing constants so screen tests can assert button
        // letter-spacing without picking up the version line.
        letterSpacing: 0.96,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Secondary footer Quit chip for the `pixelArt` variant. Implements
/// `SPEC/ui/main-menu.md` § Variant rendering — Quit button row and AC 9
/// from issue #2860: smaller than the primary wood-panel buttons, `--muted`
/// foreground, border-only chrome (`--border` top/bottom and 1px left/right
/// edges), and no brass corner brackets. Mirrors the mockup `.quit-btn`
/// element in `SPEC/ui/mockups/SHEL10002-main-menu.html`.
class _FooterQuitButton extends StatefulWidget {
  const _FooterQuitButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_FooterQuitButton> createState() => _FooterQuitButtonState();
}

class _FooterQuitButtonState extends State<_FooterQuitButton> {
  bool _hovered = false;

  void _setHover(bool entered) {
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelLarge ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final Color foreground = _hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.muted;
    final LinearGradient gradient = _hovered
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              EditorialMonoclePalette.surfaceLite,
              EditorialMonoclePalette.surface,
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              EditorialMonoclePalette.surface,
              EditorialMonoclePalette.bgDeep,
            ],
          );

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: ConstrainedBox(
            key: const Key(kMainMenuFooterQuitKey),
            constraints: const BoxConstraints(
              minHeight: kMainMenuFooterQuitMinHeight,
              minWidth: 120,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                border: Border(
                  top: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                  left: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                  right: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CtSpacing.xl,
                  vertical: CtSpacing.m,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: baseStyle.copyWith(
                      color: foreground,
                      fontFamily: editorialMonocleDisplayFontFamily,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.variant,
    required this.narrow,
    required this.onPressed,
  });

  final String label;
  final MainMenuVariant variant;
  final bool narrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (variant == MainMenuVariant.pixelArt) {
      return _PixelArtButton(
        label: label,
        narrow: narrow,
        onPressed: onPressed,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CtNinePatchButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _PixelArtButton extends StatefulWidget {
  const _PixelArtButton({
    required this.label,
    required this.onPressed,
    required this.narrow,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool narrow;
  final bool enabled;

  @override
  State<_PixelArtButton> createState() => _PixelArtButtonState();
}

class _PixelArtButtonState extends State<_PixelArtButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  static const double _bobAmount = 2.5;
  static const Duration _bobDuration = Duration(milliseconds: 800);

  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: _bobDuration);
    _bobAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  void _onHoverEnter(PointerEvent _) {
    if (!widget.enabled) return;
    setState(() => _hovered = true);
    _bobController.repeat(reverse: true);
  }

  void _onHoverExit(PointerEvent _) {
    setState(() => _hovered = false);
    _bobController.stop();
    _bobController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: MouseRegion(
        onEnter: _onHoverEnter,
        onExit: _onHoverExit,
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedBuilder(
          animation: _bobAnimation,
          builder: (context, child) {
            final double dy = _hovered
                ? (_bobAnimation.value * 2 * _bobAmount - _bobAmount)
                : 0;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: ColorFiltered(
            colorFilter: _hovered && widget.enabled
                ? ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.15),
                    BlendMode.darken,
                  )
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: CtNinePatchButton(
              onPressed: widget.enabled ? widget.onPressed : null,
              enabled: widget.enabled,
              minHeight: 48,
              gradient: CtGradients.woodPanelButtonGradient,
              pressedGradient: CtGradients.woodPanelButtonGradientPressed,
              child: Text(
                widget.label,
                style: TextStyle(
                  letterSpacing: widget.narrow
                      ? kMainMenuButtonLetterSpacingNarrow
                      : kMainMenuButtonLetterSpacingDefault,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadGameButton extends StatelessWidget {
  const _LoadGameButton({
    required this.enabled,
    required this.variant,
    required this.narrow,
    required this.onPressed,
  });

  final bool enabled;
  final MainMenuVariant variant;
  final bool narrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (variant == MainMenuVariant.pixelArt) {
      return Tooltip(
        message: enabled ? '' : l10n.mainMenu_noSavesTooltip,
        child: _PixelArtButton(
          label: l10n.mainMenu_loadGame,
          enabled: enabled,
          narrow: narrow,
          onPressed: onPressed,
        ),
      );
    }
    return Tooltip(
      message: enabled ? '' : l10n.mainMenu_noSavesTooltip,
      child: SizedBox(
        width: double.infinity,
        child: CtNinePatchButton(
          onPressed: enabled ? onPressed : null,
          enabled: enabled,
          child: Text(l10n.mainMenu_loadGame),
        ),
      ),
    );
  }
}

/// Side enumeration for a [_PixelArtScrollBracket]. Encodes which gutter
/// (left or right of the buttons region) the bracket flanks; controls the
/// horizontal offset direction of the ornamental dots and the canonical
/// stable `Key` value applied to the bracket widget so widget tests can
/// distinguish the two bracket positions independently.
enum _ScrollBracketSide { left, right }

/// Buttons-region wrapper for the `pixelArt` main-menu variant.
///
/// Stacks the wood-panel button column under two ornamental
/// [_PixelArtScrollBracket]s positioned [kMainMenuScrollBracketGutter]
/// logical pixels outside the left and right edges of the column. The
/// brackets paint across the middle
/// `1 - 2 * kMainMenuScrollBracketVerticalInset` of the column height per
/// `SPEC/ui/main-menu.md` § Buttons region and mockup
/// `.buttons-region::before` / `::after` rules. `Clip.none` lets the
/// brackets render outside the column bounds without being clipped by the
/// outer scroll view.
class _PixelArtButtonsRegion extends StatelessWidget {
  const _PixelArtButtonsRegion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          left: -kMainMenuScrollBracketGutter - kMainMenuScrollBracketWidth / 2,
          top: 0,
          bottom: 0,
          width: kMainMenuScrollBracketWidth,
          child: const _PixelArtScrollBracket(
            key: Key(kMainMenuScrollBracketLeftKey),
            side: _ScrollBracketSide.left,
          ),
        ),
        Positioned(
          right:
              -kMainMenuScrollBracketGutter - kMainMenuScrollBracketWidth / 2,
          top: 0,
          bottom: 0,
          width: kMainMenuScrollBracketWidth,
          child: const _PixelArtScrollBracket(
            key: Key(kMainMenuScrollBracketRightKey),
            side: _ScrollBracketSide.right,
          ),
        ),
      ],
    );
  }
}

/// Ornamental scroll bracket flanking the `pixelArt` buttons region.
///
/// Renders a narrow vertical gradient bar (`--accent-dim` → `--accent` →
/// `--accent-dim`, transparent at both ends) plus a single ornamental dot
/// above and below the bar, all painted at [kMainMenuScrollBracketOpacity]
/// per `SPEC/ui/main-menu.md` § Buttons region and mockup
/// `.buttons-region::before` / `::after` rules. The bar is vertically
/// centered within its parent and spans the middle
/// `1 - 2 * kMainMenuScrollBracketVerticalInset` fraction of the parent
/// height; the [side] discriminator flips the ornamental-dot horizontal
/// offset so the dots align with the corresponding mockup `box-shadow`
/// direction (`-2px` for left, `+2px` for right).
class _PixelArtScrollBracket extends StatelessWidget {
  const _PixelArtScrollBracket({super.key, required this.side});

  final _ScrollBracketSide side;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: kMainMenuScrollBracketOpacity,
      child: CustomPaint(
        painter: _PixelArtScrollBracketPainter(
          side: side,
          accent: EditorialMonoclePalette.accent,
          accentDim: EditorialMonoclePalette.accentDim,
        ),
      ),
    );
  }
}

class _PixelArtScrollBracketPainter extends CustomPainter {
  _PixelArtScrollBracketPainter({
    required this.side,
    required this.accent,
    required this.accentDim,
  });

  final _ScrollBracketSide side;
  final Color accent;
  final Color accentDim;

  static const double _barCornerRadius = 2;
  static const double _dotSize = 2;
  // Mockup `box-shadow: ±2px 6px 0 -1px var(--accent-dim)` — the 6px
  // vertical offset measures from the bar's top/bottom edge outward.
  static const double _dotVerticalOffsetFromBarEdge = 6;
  // Horizontal mockup offset is ±2px from the bar's centerline.
  static const double _dotHorizontalOffsetFromCenter = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double inset = size.height * kMainMenuScrollBracketVerticalInset;
    final double barTop = inset;
    final double barBottom = size.height - inset;
    if (barBottom <= barTop) return;

    final Rect barRect = Rect.fromLTRB(0, barTop, size.width, barBottom);
    final RRect barRRect = RRect.fromRectAndRadius(
      barRect,
      const Radius.circular(_barCornerRadius),
    );
    final Paint barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accentDim.withValues(alpha: 0),
          accentDim,
          accent,
          accentDim,
          accentDim.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.08, 0.5, 0.92, 1.0],
      ).createShader(barRect);
    canvas.drawRRect(barRRect, barPaint);

    final Paint dotPaint = Paint()..color = accentDim;
    final double horizontalOffset = side == _ScrollBracketSide.left
        ? -_dotHorizontalOffsetFromCenter
        : _dotHorizontalOffsetFromCenter;
    final double dotX = size.width / 2 + horizontalOffset;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(dotX, barTop - _dotVerticalOffsetFromBarEdge),
        width: _dotSize,
        height: _dotSize,
      ),
      dotPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(dotX, barBottom + _dotVerticalOffsetFromBarEdge),
        width: _dotSize,
        height: _dotSize,
      ),
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelArtScrollBracketPainter oldDelegate) {
    return oldDelegate.side != side ||
        oldDelegate.accent != accent ||
        oldDelegate.accentDim != accentDim;
  }
}
