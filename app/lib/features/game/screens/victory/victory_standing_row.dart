import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'victory_screen_keys.dart';
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

class VictoryStandingRowSelectPanel extends StatelessWidget {
  const VictoryStandingRowSelectPanel({
    super.key,
    required this.row,
    required this.isHuman,
    required this.isSelected,
    required this.color,
    required this.threshold,
    required this.progress,
    required this.onSelect,
    required this.textTheme,
  });

  final VictoryStandingRow row;
  final bool isHuman;
  final bool isSelected;
  final Color color;
  final int threshold;
  final double progress;
  final VoidCallback onSelect;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final titleStyle = textTheme.bodyLarge?.copyWith(
      color: isHuman || isSelected
          ? EditorialMonoclePalette.accentBright
          : EditorialMonoclePalette.fg,
      fontWeight: isHuman || isSelected ? FontWeight.w700 : FontWeight.w500,
    );
    return InkWell(
      key: VictoryScreenKeys.standingSelectKey(row.playerId),
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(row.displayName, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    l10n.victory_standingOwProgress(
                      row.owProvinceCount,
                      threshold,
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: EditorialMonoclePalette.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  VictoryOwProgressBar(
                    key: VictoryScreenKeys.standingProgressKey(row.playerId),
                    progress: progress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VictoryOwProgressBar extends StatelessWidget {
  const VictoryOwProgressBar({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * progress;
        return SizedBox(
          height: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EditorialMonoclePalette.bgDeep,
              border: Border.all(color: EditorialMonoclePalette.border),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EditorialMonoclePalette.accentBright
                        .withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class VictoryPowerBreakdownPanel extends StatelessWidget {
  const VictoryPowerBreakdownPanel({
    super.key,
    required this.breakdown,
    required this.textTheme,
  });

  final VictoryPowerScoreBreakdown breakdown;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.victory_powerBreakdownIntro,
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.victory_powerBreakdownProvinces(breakdown.totalProvinces),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          Text(
            l10n.victory_powerBreakdownRegiments(breakdown.regimentStrength),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          Text(
            l10n.victory_powerBreakdownShips(breakdown.shipCount),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          Text(
            l10n.victory_powerBreakdownTotal(breakdown.totalScore),
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
        ],
      ),
    );
  }
}
