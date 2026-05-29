import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../config/editorial_monocle_palette.dart';
import '../config/themes.dart';
import '../config/ui_screen_ids.dart';
import 'ct_brass_divider.dart';
import 'ct_compass_rose.dart';
import 'ct_fleur_de_lis_ornament.dart';
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
  horizontal: 24,
);

/// Menu container padding at viewports `≤ kMainMenuNarrowBreakpoint`.
/// Compacts horizontal padding and adds explicit vertical padding to mirror
/// the mockup `.menu-container { padding: 24px 12px; }` narrow override.
const EdgeInsets kMainMenuBodyPaddingNarrow = EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 24,
);

/// Stable `Key` value for the menu body `Padding` widget that owns the
/// responsive padding resolution. Used by widget tests to assert the
/// padding flips between [kMainMenuBodyPaddingDefault] and
/// [kMainMenuBodyPaddingNarrow] at [kMainMenuNarrowBreakpoint].
const String kMainMenuBodyPaddingKey = 'main_menu_body_padding';

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
      const SizedBox(height: 32),
      Text(version, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      _MenuButton(
        label: l10n.mainMenu_quit,
        variant: variant,
        narrow: narrow,
        onPressed: onQuit,
      ),
      const SizedBox(height: 24),
    ];
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
