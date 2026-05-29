import 'package:flutter/material.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';

/// Bottom-left horizontal row of map tool buttons for the in-game map.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Base layer display cycle,
/// Home-to-capital, Map display options, and § Corner controls chrome
/// (dark editorial-monocle). Implements `Refs #2861` R5 / S4: each
/// corner button paints the canonical 32 × 32 dp dark editorial-monocle
/// chrome (`CtGradients.railButtonGradient` surface + 1 px `--border`
/// outline with hover/pressed accent-dim shift) so the row reads as
/// dark map chrome rather than the legacy white Material overlay.
class GameMapCornerControls extends StatelessWidget {
  const GameMapCornerControls({
    required this.onCycleBaseLayerDisplayMode,
    required this.onCenterOnHomeCapital,
    required this.onOpenMapDisplayOptions,
    this.homeToCapitalEnabled = true,
    super.key,
  });

  final VoidCallback onCycleBaseLayerDisplayMode;
  final VoidCallback onCenterOnHomeCapital;
  final VoidCallback onOpenMapDisplayOptions;
  final bool homeToCapitalEnabled;

  /// Side length of each corner control button. Matches mockup
  /// `.corner-btn` 32 × 32 px (`SPEC/ui/mockups/GAME10001-game-screen.html`).
  /// The narrow-layout 24 × 24 measurement is governed by
  /// `SPEC/ui/mobile-adaptation.md` / issue #2870.
  static const double buttonSize = 32;

  /// Side length of the icon glyph centered inside the button. Matches
  /// mockup `.corner-btn img` 22 × 22 px.
  static const double iconSize = 22;

  /// Horizontal gap between adjacent corner buttons. Matches mockup
  /// `.corner-controls` `gap: 3px`.
  static const double rowGap = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapCornerIconButton(
          buttonKey: kBaseLayerCycleButtonKey,
          tooltip: l10n.mapCorner_tooltipBaseLayer,
          onTap: onCycleBaseLayerDisplayMode,
          assetPath: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
        ),
        const SizedBox(width: rowGap),
        _MapCornerIconButton(
          buttonKey: kHomeToCapitalButtonKey,
          tooltip: l10n.mapCorner_tooltipCenterCapital,
          onTap: homeToCapitalEnabled ? onCenterOnHomeCapital : null,
          assetPath: '${kAppIconAssetPrefix}ui_icon_home_capital.png',
        ),
        const SizedBox(width: rowGap),
        _MapCornerIconButton(
          buttonKey: kMapDisplayOptionsButtonKey,
          tooltip: l10n.mapCorner_tooltipMapDisplayOptions,
          onTap: onOpenMapDisplayOptions,
          assetPath: '${kAppIconAssetPrefix}ui_icon_map_options.png',
        ),
      ],
    );
  }
}

/// 32 × 32 dp dark editorial-monocle icon button used inside
/// [GameMapCornerControls].
///
/// Mirrors the mockup `.corner-btn` contract
/// (`SPEC/ui/mockups/GAME10001-game-screen.html`): the surface paints a
/// vertical `--surface-lite` → `--bg-deep` gradient via
/// [CtGradients.railButtonGradient]; a 1 px `--border` outline shifts to
/// `--accent-dim` on hover or press; the glyph cycles
/// `--accent-dim` (default) → `--accent-bright` (hover) →
/// `--accent-bright` (pressed). When [onTap] is `null` the button paints
/// at the canonical 0.4 disabled opacity (shared convention with
/// `CtBackButton` / `CtNinePatchButton` / `CtToggleSwitch`) and ignores
/// pointer input.
class _MapCornerIconButton extends StatefulWidget {
  const _MapCornerIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onTap,
    required this.assetPath,
  });

  final Key buttonKey;
  final String tooltip;
  final VoidCallback? onTap;
  final String assetPath;

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

  Color get _iconColor {
    if (!_enabled) return EditorialMonoclePalette.accentDim;
    if (_pressed || _hovered) return EditorialMonoclePalette.accentBright;
    return EditorialMonoclePalette.accentDim;
  }

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      key: widget.buttonKey,
      width: GameMapCornerControls.buttonSize,
      height: GameMapCornerControls.buttonSize,
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
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
                child: StrictAssetIcon(
                  assetPath: widget.assetPath,
                  width: GameMapCornerControls.iconSize,
                  height: GameMapCornerControls.iconSize,
                ),
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
