import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'victory_screen_keys.dart';
import 'victory_section_card.dart';
import 'victory_standing_row.dart';
import 'victory_standings.dart';

/// Great Power standings list with selection and expand/collapse.
class VictoryStandingsSection extends StatelessWidget {
  const VictoryStandingsSection({
    super.key,
    required this.standings,
    required this.humanPlayerId,
    required this.selectedPlayerId,
    required this.ownershipColors,
    required this.expandedPlayerIds,
    required this.textTheme,
    required this.onSelectPlayer,
    required this.onToggleExpand,
  });

  final List<VictoryStandingRow> standings;
  final String humanPlayerId;
  final String selectedPlayerId;
  final Map<String, (int r, int g, int b)> ownershipColors;
  final Set<String> expandedPlayerIds;
  final TextTheme textTheme;
  final void Function(String playerId) onSelectPlayer;
  final void Function(String playerId) onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return VictorySectionCard(
      key: VictoryScreenKeys.standingsSectionKey,
      title: 'Great Power standings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            key: VictoryScreenKeys.standingsHelperKey,
            appL10n(context).victory_standingsHelper,
            style: textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.muted,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in standings)
            VictoryStandingRowWidget(
              key: VictoryScreenKeys.standingRowKey(row.playerId),
              row: row,
              isHuman: row.playerId == humanPlayerId,
              isSelected: row.playerId == selectedPlayerId,
              color: victorySwatchColorFor(ownershipColors, row.playerId),
              threshold: victoryPanelMilitaryOwThreshold,
              expanded: expandedPlayerIds.contains(row.playerId),
              onSelect: () => onSelectPlayer(row.playerId),
              onToggleExpand: () => onToggleExpand(row.playerId),
              textTheme: textTheme,
            ),
        ],
      ),
    );
  }
}

Color victorySwatchColorFor(
  Map<String, (int r, int g, int b)> ownershipColors,
  String playerId,
) {
  final tuple = ownershipColors[playerId];
  if (tuple == null) {
    return EditorialMonoclePalette.muted;
  }
  return Color.fromRGBO(tuple.$1, tuple.$2, tuple.$3, 1.0);
}
