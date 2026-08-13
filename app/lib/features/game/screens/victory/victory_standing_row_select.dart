import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'victory_screen_keys.dart';
import 'victory_standings.dart';

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
