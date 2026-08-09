import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/debug_console_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';

import 'game_map_empire_left_rail_buttons.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buildEmpireRailButtons(
        game: game,
        humanPlayerId: humanPlayerId,
        topology: topology,
        orders: orders,
        bus: bus,
        narrow: narrow,
        debugConsoleEnabled: debugConsoleEnabled,
        onIconTappedWhileSelectionMode: onIconTappedWhileSelectionMode,
      ),
    );
  }
}
