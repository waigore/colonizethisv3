import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_assets.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/debug_console_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'game_screen_shared.dart';

/// Always-visible icon column for empire actions on the in-game map.
///
/// SPEC: `SPEC/ui/empire-buttons.md` § Styling (left rail), `SPEC/ui/empire-overview.md`
/// (map area left rail). Issue #2861 S3 / R4: 36 × 36 dp dark editorial-monocle
/// chrome with token-resolved gradient + border, hover/pressed states, and
/// 24 × 24 dp icon glyph. Narrow-layout measurements (26 × 26 dp) remain
/// authoritatively governed by `SPEC/ui/mobile-adaptation.md` and issue #2870.
class GameMapEmpireLeftRail extends ConsumerWidget {
  const GameMapEmpireLeftRail({
    required this.game,
    required this.humanPlayerId,
    this.onIconTappedWhileSelectionMode,
    super.key,
  });

  final ct_models.Game game;
  final String humanPlayerId;
  final VoidCallback? onIconTappedWhileSelectionMode;

  /// Side length of each rail button surface (issue #2861 R4 wide layout).
  static const double buttonSize = 36;

  /// Side length of the centered icon glyph inside a rail button.
  static const double iconSize = 24;

  /// Vertical gap between consecutive rail buttons (mockup `.left-rail`
  /// `gap: 3px`).
  static const double rowGap = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? MapTopology();
    final bus = ref.read(appEventBusProvider);
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EmpireRailButton(
          buttonKey: kEmpireProductionButtonKey,
          tooltip: 'Production',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_production.png',
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(
              ct_models.NavigateToRouteEvent(Routes.production, {
                'game': game,
                'humanPlayerId': humanPlayerId,
              }),
            );
          },
        ),
        const SizedBox(height: rowGap),
        _EmpireRailButton(
          buttonKey: kEmpireCivilianUnitsButtonKey,
          tooltip: 'Civilian Units',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_civilian_units.png',
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(const ct_models.OpenCivilianUnitsPanelEvent());
          },
        ),
        const SizedBox(height: rowGap),
        _EmpireRailButton(
          buttonKey: kEmpireMilitaryUnitsButtonKey,
          tooltip: 'Military Units',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_military_units.png',
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(const ct_models.OpenMilitaryUnitsPanelEvent());
          },
        ),
        const SizedBox(height: rowGap),
        _EmpireRailButton(
          buttonKey: kEmpireNavalUnitsButtonKey,
          tooltip: 'Naval Units',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_naval_units.png',
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(const ct_models.OpenNavalUnitsPanelEvent());
          },
        ),
        const SizedBox(height: rowGap),
        _EmpireRailButton(
          buttonKey: kEmpireDiplomacyButtonKey,
          tooltip: 'Diplomacy',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(
              ct_models.NavigateToRouteEvent(Routes.diplomacy, {
                'game': game,
                'humanPlayerId': humanPlayerId,
                'topology': topology,
                'currentOrders': orders,
              }),
            );
          },
        ),
        const SizedBox(height: rowGap),
        _EmpireRailButton(
          buttonKey: kEmpireTechnologyButtonKey,
          tooltip: 'Technology',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_technology.png',
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(
              ct_models.NavigateToRouteEvent(Routes.technology, {
                'game': game,
                'humanPlayerId': humanPlayerId,
                'currentOrders': orders,
              }),
            );
          },
        ),
        if (debugConsoleEnabled) ...<Widget>[
          const SizedBox(height: rowGap),
          _EmpireRailButton(
            buttonKey: kEmpireDebugConsoleButtonKey,
            tooltip: 'Debug Console',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
            onTap: () {
              onIconTappedWhileSelectionMode?.call();
              bus.emit(const ct_models.ToggleDebugConsolePanelEvent());
            },
          ),
        ],
      ],
    );
  }
}

/// 36 × 36 dp dark editorial-monocle button used inside [GameMapEmpireLeftRail].
///
/// Mirrors the mockup `.empire-btn` contract (`SPEC/ui/mockups/GAME10001-game-screen.html`):
/// gradient surface from `--surface-lite` → `--bg-deep`, 1 dp `--border`
/// outline, and an icon glyph that cycles `--accent-dim` (default) →
/// `--accent` (hover) → `--accent-bright` (pressed). Border lifts to
/// `--accent-dim` on hover.
class _EmpireRailButton extends StatefulWidget {
  const _EmpireRailButton({
    required this.buttonKey,
    required this.tooltip,
    required this.iconAsset,
    required this.onTap,
  });

  final Key buttonKey;
  final String tooltip;
  final String iconAsset;
  final VoidCallback onTap;

  static const Duration _animationDuration = Duration(milliseconds: 120);
  static const Curve _animationCurve = Curves.easeOut;

  @override
  State<_EmpireRailButton> createState() => _EmpireRailButtonState();
}

class _EmpireRailButtonState extends State<_EmpireRailButton> {
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

  Color get _iconColor {
    if (_pressed) return EditorialMonoclePalette.accentBright;
    if (_hovered) return EditorialMonoclePalette.accent;
    return EditorialMonoclePalette.accentDim;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Tooltip(
        message: widget.tooltip,
        child: Semantics(
          button: true,
          label: widget.tooltip,
          child: SizedBox(
            key: widget.buttonKey,
            width: GameMapEmpireLeftRail.buttonSize,
            height: GameMapEmpireLeftRail.buttonSize,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: _handlePressed,
                child: AnimatedContainer(
                  duration: _EmpireRailButton._animationDuration,
                  curve: _EmpireRailButton._animationCurve,
                  decoration: BoxDecoration(
                    gradient: CtGradients.railButtonGradient,
                    border: Border.all(color: _borderColor, width: 1),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _iconColor,
                        BlendMode.srcIn,
                      ),
                      child: StrictAssetIcon(
                        assetPath: widget.iconAsset,
                        width: GameMapEmpireLeftRail.iconSize,
                        height: GameMapEmpireLeftRail.iconSize,
                      ),
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
