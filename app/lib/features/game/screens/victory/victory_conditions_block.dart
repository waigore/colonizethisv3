import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'victory_standings.dart';

/// Victory conditions copy (military threshold, calendar end, infinite mode).
class VictoryConditionsBlock extends StatelessWidget {
  const VictoryConditionsBlock({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final threshold = victoryPanelMilitaryOwThreshold;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: EditorialMonoclePalette.fg,
    );
    final mutedStyle = bodyStyle?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.victory_conditionsMilitaryThreshold(threshold),
          style: bodyStyle?.copyWith(
            color: EditorialMonoclePalette.accentBright,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.victory_conditionsCalendarEnd,
          style: mutedStyle,
        ),
        if (game.infiniteMode) ...[
          const SizedBox(height: 8),
          Text(
            l10n.victory_conditionsInfiniteMode,
            style: mutedStyle,
          ),
        ],
      ],
    );
  }
}
