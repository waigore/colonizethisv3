part of 'game_map_corner_controls.dart';

/// 32 × 32 dp dark editorial-monocle icon button used inside
/// [GameMapCornerControls].
///
/// Mirrors the mockup `.corner-btn` contract
/// (`SPEC/ui/mockups/GAME10001-game-screen.html`): the surface paints a
/// vertical `--surface-lite` → `--bg-deep` gradient via
/// [CtGradients.railButtonGradient]; a 1 px `--border` outline shifts to
/// `--accent-dim` on hover or press. The glyph is a full-colour
/// `StrictAssetIcon` (mockup `.corner-btn img` has no colour filter); it is
/// **not** wrapped in a `ColorFiltered` / `BlendMode.srcIn` tint, so the
/// multi-colour pixel art renders natively and is unchanged across
/// interaction states (hover/press affordance lives on the border only).
/// When [onTap] is `null` the button paints at the canonical 0.4 disabled
/// opacity (shared convention with `CtBackButton` / `CtNinePatchButton` /
/// `CtToggleSwitch`) and ignores pointer input.
class _MapCornerIconButton extends StatefulWidget {
  const _MapCornerIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onTap,
    required this.assetPath,
    this.narrow = false,
  });

  final Key buttonKey;
  final String tooltip;
  final VoidCallback? onTap;
  final String assetPath;
  final bool narrow;

  /// Animation duration for hover/press border/icon-color transitions.
  /// Matches the `.empire-btn` 120 ms convention used by
  /// [GameMapEmpireLeftRail]; the mockup CSS specifies `0.15s` which we
  /// round to 120 ms for cross-button consistency.
  static const Duration _animationDuration = Duration(milliseconds: 120);
  static const Curve _animationCurve = Curves.easeOut;

  /// Disabled-state opacity shared with `CtNinePatchButton` / `CtBackButton`.
  static const double disabledOpacity = 0.4;

  @override
  State<_MapCornerIconButton> createState() => _MapCornerIconButtonState();
}

class _MapCornerIconButtonState extends State<_MapCornerIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _handleHover(bool entered) {
    if (!_enabled) return;
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void _handlePressed(bool pressed) {
    if (!_enabled) return;
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  Color get _borderColor {
    if (!_enabled) return EditorialMonoclePalette.border;
    if (_hovered || _pressed) return EditorialMonoclePalette.accentDim;
    return EditorialMonoclePalette.border;
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.narrow
        ? GameMapCornerControls.narrowButtonSize
        : GameMapCornerControls.buttonSize;
    final button = SizedBox(
      key: widget.buttonKey,
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _handlePressed,
          child: AnimatedContainer(
            duration: _MapCornerIconButton._animationDuration,
            curve: _MapCornerIconButton._animationCurve,
            decoration: BoxDecoration(
              gradient: CtGradients.railButtonGradient,
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Center(
              child: StrictAssetIcon(
                assetPath: widget.assetPath,
                width: GameMapCornerControls.iconSize,
                height: GameMapCornerControls.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
    final tooltipped = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Tooltip(
        message: widget.tooltip,
        child: Semantics(button: true, label: widget.tooltip, child: button),
      ),
    );
    if (_enabled) return tooltipped;
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: _MapCornerIconButton.disabledOpacity,
        child: tooltipped,
      ),
    );
  }
}
