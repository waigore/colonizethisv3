import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../screens/game/game_screen_shared.dart' show kTreasuryIndicatorKey;
import 'cargo_hold_indicator_support.dart';
import 'game_tab_bar.dart';
import 'game_tab_bar_indicators.dart';
import 'game_tab_bar_region_tabs.dart';

/// Stateful implementation for [GameTabBar] (Refs #4117 de-part).
class GameTabBarState extends State<GameTabBar> {
  final GlobalKey _cargoHoldAnchorKey = GlobalKey();

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
    final AppLocalizations l10n = appL10n(context);
    final String usedToken =
        widget.isCargoUsedReliable ? '${widget.cargoUsed}' : '—';
    final String capacityToken = '${widget.cargoCapacity}';
    final Color cargoNumericColor = cargoHoldNumericColor(
      used: widget.cargoUsed,
      capacity: widget.cargoCapacity,
      cargoNotDefined: widget.cargoNotDefined,
      isCargoUsedReliable: widget.isCargoUsedReliable,
    );
    final bool cargoInteractive = !widget.cargoNotDefined;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameRegionTab(
                        label: widget.oldWorldLabel,
                        selected: widget.regionIndex == 0,
                        onTap: () => widget.onRegionIndexChanged(0),
                      ),
                      const SizedBox(width: GameTabBar.regionTabGap),
                      if (kCtE2EEnabled)
                        KeyedSubtree(
                          key: kCtE2ERegionTabNewWorldKey,
                          child: GameRegionTab(
                            label: widget.newWorldLabel,
                            selected: widget.regionIndex == 1,
                            onTap: () => widget.onRegionIndexChanged(1),
                          ),
                        )
                      else
                        GameRegionTab(
                          label: widget.newWorldLabel,
                          selected: widget.regionIndex == 1,
                          onTap: () => widget.onRegionIndexChanged(1),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                key: kTreasuryIndicatorKey,
                onTap: widget.treasuryNotDefined
                    ? null
                    : () => setState(
                          () => _showExactTreasury = !_showExactTreasury,
                        ),
                child: GameTabBarTreasuryIndicator(
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
              GameTabBarCargoHoldIndicator(
                key: _cargoHoldAnchorKey,
                cargoHoldLabel: widget.cargoHoldLabel,
                labelStyle: monoBody,
                numericColor: cargoNumericColor,
                tooltip: cargoInteractive
                    ? l10n.mapControls_cargoHold_tooltip(usedToken, capacityToken)
                    : null,
                semanticsLabel: cargoInteractive
                    ? l10n.mapControls_cargoHold_semanticsLabel(
                        usedToken,
                        capacityToken,
                      )
                    : widget.cargoHoldLabel,
                onTap: cargoInteractive
                    ? () {
                        final RenderBox? tabBarBox =
                            context.findRenderObject() as RenderBox?;
                        final double chromeBottomY =
                            (tabBarBox?.localToGlobal(Offset.zero).dy ?? 0) +
                            GameTabBar.height;
                        showCargoHoldDetailsPopover(
                          context: context,
                          anchorKey: _cargoHoldAnchorKey,
                          chromeBottomY: chromeBottomY,
                          l10n: l10n,
                          cargoUsed: widget.cargoUsed,
                          cargoCapacity: widget.cargoCapacity,
                          isCargoUsedReliable: widget.isCargoUsedReliable,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: GameTabBar.clusterTrailingGap),
              widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}
