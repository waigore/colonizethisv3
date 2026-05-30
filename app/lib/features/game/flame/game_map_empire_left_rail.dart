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
/// SPEC: `SPEC/ui/empire-buttons.md` § Styling (left rail) and § Narrow rail
/// measurements; `SPEC/ui/empire-overview.md` (map area left rail);
/// `SPEC/ui/mobile-adaptation.md` § In-game shell (narrow measurements).
///
/// Wide layout (issue #2861 S3 / R4): 36 × 36 dp dark editorial-monocle chrome
/// with token-resolved gradient + border, hover/pressed states, and 24 × 24 dp
/// icon glyph.
///
/// Narrow layout (issue #2870 S3, `MediaQuery.size.width < kNarrowBreakpoint`):
/// host constructs with `narrow: true`. Rail buttons compress to 26 × 26 dp,
/// vertical gap tightens from 3 dp to 2 dp, and hover `Tooltip` widgets are
/// suppressed (touch-only viewports have no hover cursor). The `Semantics`
/// label is preserved so assistive tech still announces each action.
class GameMapEmpireLeftRail extends ConsumerWidget {
  const GameMapEmpireLeftRail({
    required this.game,
    required this.humanPlayerId,
    this.onIconTappedWhileSelectionMode,
    this.narrow = false,
    super.key,
  });

  final ct_models.Game game;
  final String humanPlayerId;
  final VoidCallback? onIconTappedWhileSelectionMode;

  /// When true, render the rail at narrow-viewport measurements per
  /// `SPEC/ui/mobile-adaptation.md` § In-game shell (issue #2870 S3).
  final bool narrow;

  /// Side length of each rail button surface (issue #2861 R4 wide layout).
  static const double buttonSize = 36;

  /// Side length of the centered icon glyph inside a rail button.
  static const double iconSize = 24;

  /// Vertical gap between consecutive rail buttons (mockup `.left-rail`
  /// `gap: 3px`).
  static const double rowGap = 3;

  /// Side length of each rail button surface under narrow layout
  /// (mockup `.empire-btn @media (max-width:600px) { width:26px; height:26px }`;
  /// authority: `SPEC/ui/mobile-adaptation.md` § In-game shell).
  static const double narrowButtonSize = 26;

  /// Vertical gap between consecutive rail buttons under narrow layout
  /// (tightened from 3 dp to keep the six-icon column inside the shorter
  /// narrow chrome stack; authority: `SPEC/ui/empire-buttons.md` § Narrow
  /// rail measurements).
  static const double narrowRowGap = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? MapTopology();
    final bus = ref.read(appEventBusProvider);
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);
    final gapHeight = narrow ? narrowRowGap : rowGap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EmpireRailButton(
          buttonKey: kEmpireProductionButtonKey,
          tooltip: 'Production',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_production.png',
          narrow: narrow,
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
        SizedBox(height: gapHeight),
        _EmpireRailButton(
          buttonKey: kEmpireTradeButtonKey,
          tooltip: 'Trade',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_trade.png',
          narrow: narrow,
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(
              ct_models.NavigateToRouteEvent(Routes.trade, {
                'game': game,
                'humanPlayerId': humanPlayerId,
              }),
            );
          },
        ),
        SizedBox(height: gapHeight),
        _EmpireRailButton(
          buttonKey: kEmpireCivilianUnitsButtonKey,
          tooltip: 'Civilian Units',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_civilian_units.png',
          narrow: narrow,
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(const ct_models.OpenCivilianUnitsPanelEvent());
          },
        ),
        SizedBox(height: gapHeight),
        _EmpireRailButton(
          buttonKey: kEmpireMilitaryUnitsButtonKey,
          tooltip: 'Military Units',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_military_units.png',
          narrow: narrow,
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(const ct_models.OpenMilitaryUnitsPanelEvent());
          },
        ),
        SizedBox(height: gapHeight),
        _EmpireRailButton(
          buttonKey: kEmpireNavalUnitsButtonKey,
          tooltip: 'Naval Units',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_naval_units.png',
          narrow: narrow,
          onTap: () {
            onIconTappedWhileSelectionMode?.call();
            bus.emit(const ct_models.OpenNavalUnitsPanelEvent());
          },
        ),
        SizedBox(height: gapHeight),
        _EmpireRailButton(
          buttonKey: kEmpireDiplomacyButtonKey,
          tooltip: 'Diplomacy',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_diplomacy.png',
          narrow: narrow,
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
        SizedBox(height: gapHeight),
        _EmpireRailButton(
          buttonKey: kEmpireTechnologyButtonKey,
          tooltip: 'Technology',
          iconAsset: '${kAppIconAssetPrefix}ui_icon_technology.png',
          narrow: narrow,
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
          SizedBox(height: gapHeight),
          _EmpireRailButton(
            buttonKey: kEmpireDebugConsoleButtonKey,
            tooltip: 'Debug Console',
            iconAsset: '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
            narrow: narrow,
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
    this.narrow = false,
  });

  final Key buttonKey;
  final String tooltip;
  final String iconAsset;
  final VoidCallback onTap;
  final bool narrow;

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
