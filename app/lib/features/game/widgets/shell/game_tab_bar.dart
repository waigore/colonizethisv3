import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_assets.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../screens/game/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kTreasuryIndicatorKey;

part 'game_tab_bar_region_tabs.dart';
part 'game_tab_bar_indicators.dart';
part 'game_tab_bar_state.dart';

/// In-game shell tab bar: 34 px dark editorial-monocle chrome with region
/// tabs, treasury + cargo indicators, and a trailing news-toggle slot.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Region tabs / § Tab bar chrome,
/// mockup `SPEC/ui/mockups/GAME10001-game-screen.html` (`.tabbar`,
/// `.region-tab`, `.treasury`, `.cargo-hold`). Issue #2861 S2.
///
/// All colours resolve from [EditorialMonoclePalette] tokens; no hard-coded
/// hex literals.
class GameTabBar extends StatefulWidget {
  const GameTabBar({
    super.key,
    required this.regionIndex,
    required this.onRegionIndexChanged,
    required this.oldWorldLabel,
    required this.newWorldLabel,
    required this.treasury,
    required this.treasuryDelta,
    required this.treasuryNotDefined,
    required this.cargoUsed,
    required this.cargoCapacity,
    required this.cargoNotDefined,
    required this.isCargoUsedReliable,
    required this.cargoHoldLabel,
    required this.trailing,
    this.treasuryObserveLabel,
  });

  final int regionIndex;
  final ValueChanged<int> onRegionIndexChanged;
  final String oldWorldLabel;
  final String newWorldLabel;
  final int treasury;
  final int? treasuryDelta;
  final bool treasuryNotDefined;
  final String? treasuryObserveLabel;
  final int cargoUsed;
  final int cargoCapacity;
  final bool cargoNotDefined;
  final bool isCargoUsedReliable;
  final String cargoHoldLabel;
  final Widget trailing;

  /// Fixed bar height (issue #2861 R2 / mockup `--tabbar-h: 34px`).
  static const double height = 34;

  /// Bottom-border width under the tab bar chrome.
  static const double borderWidth = 1;

  /// Outer horizontal padding inside the bar (mockup `.tabbar { padding: 0 6px }`).
  static const double horizontalPadding = 6;

  /// Gap between region tabs (mockup `.tabbar { gap: 2px }`).
  static const double regionTabGap = 2;

  /// Leading margin (4 dp) between the cargo hold indicator and the
  /// trailing news toggle (mockup `.news-toggle { margin-left: 4px }`,
  /// issue #2861 M1/M3).
  static const double clusterTrailingGap = 4;

  /// Stable key for widget tests that pin the chrome surface.
  static const Key surfaceKey = Key('game_tab_bar_surface');

  @override
  State<GameTabBar> createState() => _GameTabBarState();
}
