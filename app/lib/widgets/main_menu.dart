import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../config/app_assets.dart';
import '../config/themes.dart';
import 'ct_nine_patch_button.dart';

/// Visual variant of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuVariant {
  /// Standard Flutter widgets with colonial theme (no pixel-art assets).
  plain,

  /// Same layout with pixel-art assets from SPEC/ui/main-menu.md.
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
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                kMainMenuBackgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => Container(color: darkWood),
              ),
            ),
            Theme(data: AppThemes.colonialPixelArt, child: content),
          ],
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
    // Pixel-art logo asset already contains "ColonizeThis"; no overlay. SPEC/ui/main-menu.md.
    return SizedBox(
      height: 64,
      child: Image.asset(
        kMainMenuLogoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, _, _) {
          return const SizedBox.shrink();
        },
      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: _MainMenuBodyContent(
                variant: variant,
                showAfterVictorySubtitle: showAfterVictorySubtitle,
                loadGameEnabled: loadGameEnabled,
                resumeGameVisible: resumeGameVisible,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: _menuChildren(context),
    );
  }

  List<Widget> _menuChildren(BuildContext context) {
    final l10n = appL10n(context);
    return [
      const SizedBox(height: 48),
      logoBuilder(context),
      if (showAfterVictorySubtitle) ...[
        const SizedBox(height: 12),
        Text(
          l10n.mainMenu_subtitleAfterVictory,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
      const SizedBox(height: 32),
      _MenuButton(
        label: l10n.mainMenu_newGame,
        variant: variant,
        onPressed: onNewGame,
      ),
      if (resumeGameVisible) ...[
        const SizedBox(height: 12),
        _MenuButton(
          label: l10n.mainMenu_resumeGame,
          variant: variant,
          onPressed: onResumeGame!,
        ),
      ],
      const SizedBox(height: 12),
      _LoadGameButton(
        enabled: loadGameEnabled,
        variant: variant,
        onPressed: onLoadGame,
      ),
      const SizedBox(height: 12),
      _MenuButton(
        label: l10n.mainMenu_settings,
        variant: variant,
        onPressed: onSettings,
      ),
      const SizedBox(height: 32),
      Text(version, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      _MenuButton(
        label: l10n.mainMenu_quit,
        variant: variant,
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
    required this.onPressed,
  });

  final String label;
  final MainMenuVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (variant == MainMenuVariant.pixelArt) {
      return _PixelArtButton(label: label, onPressed: onPressed);
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
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
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
              child: Text(widget.label),
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
    required this.onPressed,
  });

  final bool enabled;
  final MainMenuVariant variant;
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
