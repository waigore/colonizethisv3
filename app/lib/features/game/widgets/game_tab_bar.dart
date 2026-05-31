import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/app_assets.dart';
import '../../../config/ct_e2e.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../flame/game_screen_shared.dart'
    show kCargoHoldIndicatorKey, kTreasuryIndicatorKey;

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

  /// Gap between the centered cluster and the trailing news toggle.
  static const double clusterTrailingGap = 4;

  /// Stable key for widget tests that pin the chrome surface.
  static const Key surfaceKey = Key('game_tab_bar_surface');

  @override
  State<GameTabBar> createState() => _GameTabBarState();
}

class _GameTabBarState extends State<GameTabBar> {
  static final NumberFormat _exactTreasuryFormat =
      NumberFormat.decimalPattern();
  static final NumberFormat _abbrevTreasuryFormat = NumberFormat.compact(
    locale: 'en_US',
  );
  bool _showExactTreasury = true;

  String _formatTreasury(int value) {
    if (_showExactTreasury) {
      return _exactTreasuryFormat.format(value);
    }
    final compactRaw = _abbrevTreasuryFormat.format(value);
    final compact = compactRaw.replaceAll('K', 'k');
    if (compact.contains('.') || !compact.endsWith('k')) {
      return compact;
    }
    return compact.replaceFirst('k', '.0k');
  }

  Color? _treasuryDeltaColor(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    return delta > 0
        ? EditorialMonoclePalette.success
        : EditorialMonoclePalette.danger;
  }

  String? _treasuryDeltaLabel(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    if (delta > 0) {
      return '+$delta';
    }
    return '$delta';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle monoBody = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.0,
        );
    final treasuryLabel = widget.treasuryNotDefined
        ? (widget.treasuryObserveLabel ?? '—')
        : _formatTreasury(widget.treasury);
    final deltaLabel = widget.treasuryNotDefined
        ? null
        : _treasuryDeltaLabel(widget.treasuryDelta);
    final deltaColor =
        _treasuryDeltaColor(deltaLabel == null ? null : widget.treasuryDelta);

    return SizedBox(
      key: GameTabBar.surfaceKey,
      height: GameTabBar.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorialMonoclePalette.surface,
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.border,
              width: GameTabBar.borderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GameTabBar.horizontalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GameRegionTab(
                              label: widget.oldWorldLabel,
                              selected: widget.regionIndex == 0,
                              onTap: () => widget.onRegionIndexChanged(0),
                            ),
                            const SizedBox(width: GameTabBar.regionTabGap),
                            if (kCtE2EEnabled)
                              KeyedSubtree(
                                key: kCtE2ERegionTabNewWorldKey,
                                child: _GameRegionTab(
                                  label: widget.newWorldLabel,
                                  selected: widget.regionIndex == 1,
                                  onTap: () =>
                                      widget.onRegionIndexChanged(1),
                                ),
                              )
                            else
                              _GameRegionTab(
                                label: widget.newWorldLabel,
                                selected: widget.regionIndex == 1,
                                onTap: () => widget.onRegionIndexChanged(1),
                              ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              key: kTreasuryIndicatorKey,
                              onTap: widget.treasuryNotDefined
                                  ? null
                                  : () => setState(
                                        () => _showExactTreasury =
                                            !_showExactTreasury,
                                      ),
                              child: _TreasuryIndicator(
                                treasuryLabel: treasuryLabel,
                                deltaLabel: deltaLabel,
                                deltaColor: deltaColor,
                                labelStyle: monoBody.copyWith(
                                  color: EditorialMonoclePalette.accentDim,
                                ),
                                deltaStyle: monoBody.copyWith(
                                  fontSize: 10,
                                  color: deltaColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _CargoHoldIndicator(
                              cargoHoldLabel: widget.cargoHoldLabel,
                              labelStyle: monoBody.copyWith(
                                color: EditorialMonoclePalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: GameTabBar.clusterTrailingGap),
              Align(
                alignment: Alignment.center,
                child: widget.trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameRegionTab extends StatelessWidget {
  const _GameRegionTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _horizontalPadding = 12;
  static const double _verticalPadding = 4;
  static const double _activeBottomBorderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle labelStyle = (theme.textTheme.bodySmall ??
            const TextStyle(fontSize: 12))
        .copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.03 * 11,
          color: selected
              ? EditorialMonoclePalette.accent
              : EditorialMonoclePalette.muted,
        );

    final BoxDecoration decoration = selected
        ? BoxDecoration(
            color: EditorialMonoclePalette.bg,
            border: Border(
              left: BorderSide(color: EditorialMonoclePalette.accentDim),
              top: BorderSide(color: EditorialMonoclePalette.accentDim),
              right: BorderSide(color: EditorialMonoclePalette.accentDim),
              bottom: BorderSide(
                color: EditorialMonoclePalette.accent,
                width: _activeBottomBorderWidth,
              ),
            ),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                EditorialMonoclePalette.bgDeep,
                EditorialMonoclePalette.surface,
              ],
            ),
            border: Border(
              left: BorderSide(color: EditorialMonoclePalette.border),
              top: BorderSide(color: EditorialMonoclePalette.border),
              right: BorderSide(color: EditorialMonoclePalette.border),
            ),
          );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
          decoration: decoration,
          child: Text(label, style: labelStyle),
        ),
      ),
    );
  }
}

class _TreasuryIndicator extends StatelessWidget {
  const _TreasuryIndicator({
    required this.treasuryLabel,
    required this.deltaLabel,
    required this.deltaColor,
    required this.labelStyle,
    required this.deltaStyle,
  });

  final String treasuryLabel;
  final String? deltaLabel;
  final Color? deltaColor;
  final TextStyle labelStyle;
  final TextStyle deltaStyle;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StrictAssetIcon(
            assetPath: '${kAppIconAssetPrefix}ui_icon_treasury_coin.png',
            width: _iconSize,
            height: _iconSize,
          ),
          const SizedBox(width: 4),
          Text(treasuryLabel, style: labelStyle),
          if (deltaLabel != null) ...[
            const SizedBox(width: 4),
            Text(deltaLabel!, style: deltaStyle),
          ],
        ],
      ),
    );
  }
}

class _CargoHoldIndicator extends StatelessWidget {
  const _CargoHoldIndicator({
    required this.cargoHoldLabel,
    required this.labelStyle,
  });

  final String cargoHoldLabel;
  final TextStyle labelStyle;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: kCargoHoldIndicatorKey,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: EditorialMonoclePalette.border,
            width: 1,
          ),
        ),
      ),
      margin: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StrictAssetIcon(
            assetPath: '${kAppIconAssetPrefix}ui_icon_cargo_hold.png',
            width: _iconSize,
            height: _iconSize,
          ),
          const SizedBox(width: 4),
          Text(cargoHoldLabel, style: labelStyle),
        ],
      ),
    );
  }
}
