import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'victory_power_breakdown_panel.dart';
import 'victory_screen_keys.dart';
import 'victory_standing_row_select.dart';
import 'victory_standings.dart';

/// One expandable Great Power row in the Victory standings list.
class VictoryStandingRowWidget extends StatelessWidget {
  const VictoryStandingRowWidget({
    super.key,
    required this.row,
    required this.isHuman,
    required this.isSelected,
    required this.color,
    required this.threshold,
    required this.expanded,
    required this.onSelect,
    required this.onToggleExpand,
    required this.textTheme,
  });

  final VictoryStandingRow row;
  final bool isHuman;
  final bool isSelected;
  final Color color;
  final int threshold;
  final bool expanded;
  final VoidCallback onSelect;
  final VoidCallback onToggleExpand;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final breakdown = row.powerBreakdown;
    final progress = threshold <= 0
        ? 0.0
        : (row.owProvinceCount / threshold).clamp(0.0, 1.0);
    return Column(
      children: [
        VictoryStandingRowHeader(
          row: row,
          isHuman: isHuman,
          isSelected: isSelected,
          color: color,
          threshold: threshold,
          progress: progress,
          expanded: expanded,
          onSelect: onSelect,
          onToggleExpand: onToggleExpand,
          textTheme: textTheme,
        ),
        if (expanded)
          VictoryPowerBreakdownPanel(
            key: VictoryScreenKeys.powerBreakdownKey(row.playerId),
            breakdown: breakdown,
            textTheme: textTheme,
          ),
        Divider(height: 1, color: EditorialMonoclePalette.border),
      ],
    );
  }
}

class VictoryStandingRowHeader extends StatelessWidget {
  const VictoryStandingRowHeader({
    super.key,
    required this.row,
    required this.isHuman,
    required this.isSelected,
    required this.color,
    required this.threshold,
    required this.progress,
    required this.expanded,
    required this.onSelect,
    required this.onToggleExpand,
    required this.textTheme,
  });

  final VictoryStandingRow row;
  final bool isHuman;
  final bool isSelected;
  final Color color;
  final int threshold;
  final double progress;
  final bool expanded;
  final VoidCallback onSelect;
  final VoidCallback onToggleExpand;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected
            ? EditorialMonoclePalette.surfaceLite.withValues(alpha: 0.35)
            : null,
        border: isSelected
            ? Border.all(color: EditorialMonoclePalette.accentDim)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: VictoryStandingRowSelectPanel(
              row: row,
              isHuman: isHuman,
              isSelected: isSelected,
              color: color,
              threshold: threshold,
              progress: progress,
              onSelect: onSelect,
              textTheme: textTheme,
            ),
          ),
          InkWell(
            key: VictoryScreenKeys.standingExpandKey(row.playerId),
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: EditorialMonoclePalette.muted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
