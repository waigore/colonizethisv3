import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../screens/game/game_screen_shared.dart' show kTreasuryIndicatorKey;
import 'cargo_hold_indicator_support.dart';
import 'labour_feeding_indicator_support.dart';
import 'game_tab_bar.dart';
import 'game_tab_bar_indicators.dart';
import 'old_world_race_chip.dart';
import 'treasury_details_indicator_support.dart';

/// Right-side HUD cluster: treasury, cargo, labour/feeding, race chip, trailing.
class GameTabBarHudCluster extends StatelessWidget {
  const GameTabBarHudCluster({
    super.key,
    required this.bar,
    required this.l10n,
    required this.monoBody,
    required this.treasuryLabel,
    required this.deltaLabel,
    required this.deltaColor,
    required this.cargoNumericColor,
    required this.cargoInteractive,
    required this.labourFeedingInteractive,
    required this.labourNumericColor,
    required this.showExactTreasury,
    required this.onShowExactTreasuryChanged,
    required this.treasuryAnchorKey,
    required this.cargoHoldAnchorKey,
    required this.labourFeedingAnchorKey,
  });

  final GameTabBar bar;
  final AppLocalizations l10n;
  final TextStyle monoBody;
  final String treasuryLabel;
  final String? deltaLabel;
  final Color? deltaColor;
  final Color cargoNumericColor;
  final bool cargoInteractive;
  final bool labourFeedingInteractive;
  final Color labourNumericColor;
  final bool showExactTreasury;
  final ValueChanged<bool> onShowExactTreasuryChanged;
  final GlobalKey treasuryAnchorKey;
  final GlobalKey cargoHoldAnchorKey;
  final GlobalKey labourFeedingAnchorKey;

  double _chromeBottomY(BuildContext context) {
    final RenderBox? tabBarBox = context.findRenderObject() as RenderBox?;
    return (tabBarBox?.localToGlobal(Offset.zero).dy ?? 0) + GameTabBar.height;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _treasuryIndicator(context),
        _cargoHoldIndicator(context),
        if (bar.showLabourFeedingIndicator) _labourFeedingIndicator(context),
        if (bar.oldWorldRace != null)
          OldWorldRaceChip(
            snapshot: bar.oldWorldRace!,
            narrow: bar.oldWorldRaceNarrow,
            onTap: bar.onOldWorldRaceTap,
          ),
        const SizedBox(width: GameTabBar.clusterTrailingGap),
        bar.trailing,
      ],
    );
  }

  Widget _treasuryIndicator(BuildContext context) {
    return GestureDetector(
      key: kTreasuryIndicatorKey,
      onTap: bar.treasuryNotDefined
          ? null
          : () {
              showTreasuryDetailsPopover(
                context: context,
                anchorKey: treasuryAnchorKey,
                chromeBottomY: _chromeBottomY(context),
                l10n: l10n,
                treasury: bar.treasury,
                projectedDelta: bar.treasuryDelta,
                committedLines: bar.treasuryCommittedLines,
                showExact: showExactTreasury,
                onShowExactChanged: onShowExactTreasuryChanged,
              );
            },
      child: KeyedSubtree(
        key: treasuryAnchorKey,
        child: GameTabBarTreasuryIndicator(
          treasuryLabel: treasuryLabel,
          deltaLabel: deltaLabel,
          deltaColor: deltaColor,
          labelStyle: monoBody.copyWith(
            color: EditorialMonoclePalette.accentDim,
          ),
          deltaStyle: monoBody.copyWith(fontSize: 10, color: deltaColor),
        ),
      ),
    );
  }

  Widget _cargoHoldIndicator(BuildContext context) {
    final String usedToken = bar.isCargoUsedReliable ? '${bar.cargoUsed}' : '—';
    final String capacityToken = '${bar.cargoCapacity}';
    return GameTabBarCargoHoldIndicator(
      key: cargoHoldAnchorKey,
      cargoHoldLabel: bar.cargoHoldLabel,
      labelStyle: monoBody,
      numericColor: cargoNumericColor,
      tooltip: cargoInteractive
          ? l10n.mapControls_cargoHold_tooltip(usedToken, capacityToken)
          : null,
      semanticsLabel: cargoInteractive
          ? l10n.mapControls_cargoHold_semanticsLabel(usedToken, capacityToken)
          : bar.cargoHoldLabel,
      onTap: cargoInteractive
          ? () {
              showCargoHoldDetailsPopover(
                context: context,
                anchorKey: cargoHoldAnchorKey,
                chromeBottomY: _chromeBottomY(context),
                l10n: l10n,
                cargoUsed: bar.cargoUsed,
                cargoCapacity: bar.cargoCapacity,
                isCargoUsedReliable: bar.isCargoUsedReliable,
              );
            }
          : null,
    );
  }

  Widget _labourFeedingIndicator(BuildContext context) {
    return GameTabBarLabourFeedingIndicator(
      key: labourFeedingAnchorKey,
      labourFeedingLabel: bar.labourFeedingLabel,
      labelStyle: monoBody,
      numericColor: labourNumericColor,
      tooltip: labourFeedingInteractive
          ? l10n.mapControls_labourFeeding_tooltip(
              bar.labourReadiness!.effectiveLabour.toString(),
              bar.labourReadiness!.fullCapacity.toString(),
            )
          : null,
      semanticsLabel: labourFeedingInteractive
          ? l10n.mapControls_labourFeeding_semanticsLabel(
              bar.labourReadiness!.effectiveLabour.toString(),
              bar.labourReadiness!.fullCapacity.toString(),
            )
          : bar.labourFeedingLabel,
      onTap: labourFeedingInteractive
          ? () {
              showLabourFeedingDetailsPopover(
                context: context,
                anchorKey: labourFeedingAnchorKey,
                chromeBottomY: _chromeBottomY(context),
                l10n: l10n,
                labourReadiness: bar.labourReadiness!,
                forcesFeeding: bar.forcesFeeding!,
              );
            }
          : null,
    );
  }
}
