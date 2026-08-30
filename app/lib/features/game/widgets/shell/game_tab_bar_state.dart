import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'cargo_hold_indicator_support.dart';
import 'labour_feeding_indicator_support.dart';
import 'game_tab_bar.dart';
import 'game_tab_bar_hud_cluster.dart';
import 'game_tab_bar_region_tabs.dart';
import 'treasury_details_indicator_support.dart';

/// Stateful implementation for [GameTabBar] (Refs #4117 de-part).
class GameTabBarState extends State<GameTabBar> {
  final GlobalKey _treasuryAnchorKey = GlobalKey();
  final GlobalKey _cargoHoldAnchorKey = GlobalKey();
  final GlobalKey _labourFeedingAnchorKey = GlobalKey();

  bool _showExactTreasury = true;

  Color? _treasuryDeltaColor(int? delta) {
    if (delta == null || delta == 0) {
      return null;
    }
    return delta > 0
        ? EditorialMonoclePalette.success
        : EditorialMonoclePalette.danger;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle monoBody = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(fontFamily: 'monospace', fontSize: 11, height: 1.0);
    final treasuryLabel = widget.treasuryNotDefined
        ? (widget.treasuryObserveLabel ?? '—')
        : formatTreasuryAmount(widget.treasury, showExact: _showExactTreasury);
    final deltaLabel = widget.treasuryNotDefined
        ? null
        : formatTreasuryDeltaLabel(widget.treasuryDelta);
    final deltaColor = _treasuryDeltaColor(
      deltaLabel == null ? null : widget.treasuryDelta,
    );
    final AppLocalizations l10n = appL10n(context);
    final Color cargoNumericColor = cargoHoldNumericColor(
      used: widget.cargoUsed,
      capacity: widget.cargoCapacity,
      cargoNotDefined: widget.cargoNotDefined,
      isCargoUsedReliable: widget.isCargoUsedReliable,
    );
    final bool cargoInteractive = !widget.cargoNotDefined;
    final bool labourFeedingInteractive =
        widget.showLabourFeedingIndicator && !widget.labourFeedingNotDefined;
    final Color labourNumericColor =
        widget.labourReadiness == null || widget.forcesFeeding == null
        ? EditorialMonoclePalette.muted
        : labourFeedingNumericColor(
            labourReadiness: widget.labourReadiness!,
            forcesFeeding: widget.forcesFeeding!,
            notDefined: widget.labourFeedingNotDefined,
          );

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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Row(
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
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: GameTabBarHudCluster(
                        bar: widget,
                        l10n: l10n,
                        monoBody: monoBody,
                        treasuryLabel: treasuryLabel,
                        deltaLabel: deltaLabel,
                        deltaColor: deltaColor,
                        cargoNumericColor: cargoNumericColor,
                        cargoInteractive: cargoInteractive,
                        labourFeedingInteractive: labourFeedingInteractive,
                        labourNumericColor: labourNumericColor,
                        showExactTreasury: _showExactTreasury,
                        onShowExactTreasuryChanged: (bool next) {
                          setState(() => _showExactTreasury = next);
                        },
                        treasuryAnchorKey: _treasuryAnchorKey,
                        cargoHoldAnchorKey: _cargoHoldAnchorKey,
                        labourFeedingAnchorKey: _labourFeedingAnchorKey,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
