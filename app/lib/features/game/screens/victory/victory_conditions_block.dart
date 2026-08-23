import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../campaign_calendar_clock.dart';
import 'victory_standings.dart';

/// Victory conditions copy (military threshold, calendar remaining, infinite).
class VictoryConditionsBlock extends StatelessWidget {
  const VictoryConditionsBlock({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final threshold = victoryPanelMilitaryOwThreshold;
    final clock = CampaignCalendarClock.fromGame(game);
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: EditorialMonoclePalette.fg);
    final mutedStyle = bodyStyle?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final calendarCopy = _calendarCopy(l10n, clock, game);
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
        if (calendarCopy != null) ...[
          const SizedBox(height: 8),
          Text(calendarCopy, style: mutedStyle),
        ],
        if (game.infiniteMode) ...[
          const SizedBox(height: 8),
          Text(l10n.victory_conditionsInfiniteMode, style: mutedStyle),
        ],
      ],
    );
  }
}

String? _calendarCopy(
  AppLocalizations l10n,
  CampaignCalendarClock clock,
  Game game,
) {
  switch (clock.kind) {
    case CampaignCalendarClockKind.remaining:
      return l10n.victory_conditionsCalendarRemaining(
        clock.currentYear,
        clock.lastCampaignYear,
        clock.remainingYears,
        clock.remainingTurns,
      );
    case CampaignCalendarClockKind.lastYear:
      return l10n.victory_conditionsCalendarLastYear(clock.lastCampaignYear);
    case CampaignCalendarClockKind.noHaltOnMapping:
      return l10n.victory_conditionsCalendarNoHalt(
        TurnTimeMapping.campaignCalendarStopStartYear,
      );
    case CampaignCalendarClockKind.omitCountdown:
      if (game.infiniteMode) {
        return null;
      }
      return l10n.victory_conditionsCalendarEnded;
  }
}
