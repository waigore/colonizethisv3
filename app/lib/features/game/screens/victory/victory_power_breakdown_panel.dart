import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'victory_standings.dart';

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
