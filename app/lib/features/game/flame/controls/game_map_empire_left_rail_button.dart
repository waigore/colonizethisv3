import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/strict_asset_icon.dart';

import 'game_map_empire_left_rail.dart';

/// 36 × 36 dp dark editorial-monocle button used inside [GameMapEmpireLeftRail].
///
/// Mirrors the mockup `.empire-btn` contract (`SPEC/ui/mockups/GAME10001-game-screen.html`):
/// gradient surface from `--surface-lite` → `--bg-deep`, 1 dp `--border`
/// outline, and a full-colour `StrictAssetIcon` glyph at 24 × 24 dp with no
/// `srcIn` tint. Border lifts to `--accent-dim` on hover/press; the icon
/// colours are unchanged across interaction states.
class EmpireRailButton extends StatefulWidget {
  const EmpireRailButton({
    required this.buttonKey,
    required this.tooltip,
    required this.iconAsset,
    required this.onTap,
    this.narrow = false,
    super.key,
  });

  final Key buttonKey;
  final String tooltip;
  final String iconAsset;
  final VoidCallback onTap;
  final bool narrow;

  static const Duration _animationDuration = Duration(milliseconds: 120);
  static const Curve _animationCurve = Curves.easeOut;

  @override
  State<EmpireRailButton> createState() => _EmpireRailButtonState();
}

class _EmpireRailButtonState extends State<EmpireRailButton> {
  bool _hovered = false;
  bool _pressed = false;

  void _handleHover(bool entered) {
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  void _handlePressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  Color get _borderColor {
    if (_hovered || _pressed) {
      return EditorialMonoclePalette.accentDim;
    }
    return EditorialMonoclePalette.border;
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.narrow
        ? GameMapEmpireLeftRail.narrowButtonSize
        : GameMapEmpireLeftRail.buttonSize;
    final surface = SizedBox(
      key: widget.buttonKey,
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _handlePressed,
          child: AnimatedContainer(
            duration: EmpireRailButton._animationDuration,
            curve: EmpireRailButton._animationCurve,
            decoration: BoxDecoration(
              gradient: CtGradients.railButtonGradient,
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Center(
              child: StrictAssetIcon(
                assetPath: widget.iconAsset,
                width: GameMapEmpireLeftRail.iconSize,
                height: GameMapEmpireLeftRail.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
    final labelled = Semantics(
      button: true,
      label: widget.tooltip,
      child: surface,
    );
    final tooltipped = widget.narrow
        ? labelled
        : Tooltip(message: widget.tooltip, child: labelled);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: tooltipped,
    );
  }
}
