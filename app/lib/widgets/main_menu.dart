import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../config/themes.dart';

/// Visual variant of the main menu. SPEC/ui/main-menu.md; UXD 03a.
enum MainMenuVariant {
  /// Standard Flutter widgets with colonial theme (no pixel-art assets).
  plain,

  /// Same layout with pixel-art assets from SPEC/ui/main-menu.md.
  pixelArt,
}

/// Asset paths for pixel-art variant. SPEC/ui/main-menu.md.
const String _kAssetLogo = 'assets/images/ui_main_menu_logo.png';
const String _kAssetButton = 'assets/images/ui_main_menu_button.png';
const String _kAssetBackground = 'assets/images/ui_main_menu_background.png';

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
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
  });

  final MainMenuVariant variant;
  final MainMenuState state;
  final String version;
  final VoidCallback onNewGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  bool get _loadGameEnabled => state != MainMenuState.noSaves;
  bool get _showAfterVictorySubtitle => state == MainMenuState.afterVictory;

  @override
  Widget build(BuildContext context) {
    final Widget content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(context),
                if (_showAfterVictorySubtitle) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Congratulations, you won your last game.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(flex: 2),
                _MenuButton(
                  label: 'New Game',
                  variant: variant,
                  onPressed: onNewGame,
                ),
                const SizedBox(height: 12),
                _LoadGameButton(
                  enabled: _loadGameEnabled,
                  variant: variant,
                  onPressed: onLoadGame,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: 'Settings',
                  variant: variant,
                  onPressed: onSettings,
                ),
                const Spacer(flex: 2),
                Text(
                  version,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _MenuButton(
                  label: 'Quit',
                  variant: variant,
                  onPressed: onQuit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (variant == MainMenuVariant.pixelArt) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                _kAssetBackground,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF5D3A1A),
                ),
              ),
            ),
            Theme(
              data: AppThemes.colonialPixelArt,
              child: content,
            ),
          ],
        ),
      );
    }

    return Scaffold(body: content);
  }

  Widget _buildLogo(BuildContext context) {
    if (variant == MainMenuVariant.plain) {
      return Text(
        'ColonizeThis V3',
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      );
    }
    // Pixel-art logo asset already contains "ColonizeThis"; no overlay. SPEC/ui/main-menu.md.
    return SizedBox(
      height: 64,
      child: Image.asset(
        _kAssetLogo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) {
          return const SizedBox.shrink();
        },
      ),
    );
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
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
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
    _bobController = AnimationController(
      vsync: this,
      duration: _bobDuration,
    );
    _bobAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
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
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedBuilder(
          animation: _bobAnimation,
          builder: (context, child) {
            final double dy = _hovered ? (_bobAnimation.value * 2 * _bobAmount - _bobAmount) : 0;
            return Transform.translate(
              offset: Offset(0, dy),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled ? widget.onPressed : null,
              child: ColorFiltered(
                colorFilter: _hovered && widget.enabled
                    ? ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.15),
                        BlendMode.darken,
                      )
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _kAssetButton,
                      centerSlice: const Rect.fromLTWH(24, 18, 75, 21),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) {
                        Logger().w(
                          'logic: main_menu button asset not found, using fallback',
                        );
                        return Container(
                          color: const Color(0xFF5D3A1A),
                        );
                      },
                    ),
                    Center(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: widget.enabled
                                  ? const Color(0xFFF5F5DC)
                                  : Colors.grey,
                            ),
                      ),
                    ),
                  ],
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
    required this.onPressed,
  });

  final bool enabled;
  final MainMenuVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (variant == MainMenuVariant.pixelArt) {
      return Tooltip(
        message: enabled ? '' : 'No saved games. Start a new game first.',
        child: _PixelArtButton(
          label: 'Load Game',
          enabled: enabled,
          onPressed: onPressed,
        ),
      );
    }
    return Tooltip(
      message: enabled ? '' : 'No saved games. Start a new game first.',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          child: const Text('Load Game'),
        ),
      ),
    );
  }
}
