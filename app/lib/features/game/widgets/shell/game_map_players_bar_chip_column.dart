import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../screens/game/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;
import 'game_map_players_bar.dart';
import 'game_map_players_bar_chip.dart';

Widget buildGameMapPlayersBarChipColumn({
  required BuildContext context,
  required Game game,
  required String? highlightPlayerId,
}) {
  final roster = GameMapPlayersBar.greatPowerRoster(game);
  if (roster.isEmpty) {
    return const SizedBox.shrink();
  }
  final ownershipColors = factionOwnershipColorMapForOldWorld(game);
  final scoreFormat = NumberFormat.decimalPattern('en_US');
  final theme = Theme.of(context);
  final mutedNameStyle =
      (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
        color: EditorialMonoclePalette.muted,
        fontWeight: FontWeight.w500,
        fontSize: 10,
      );
  final accentNameStyle = mutedNameStyle.copyWith(
    color: EditorialMonoclePalette.accent,
    fontWeight: FontWeight.w600,
  );
  final scoreStyle =
      (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
        color: EditorialMonoclePalette.accentDim,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        fontFamily: 'monospace',
        fontSize: 9,
      );
  final chips = <Widget>[];
  for (var i = 0; i < roster.length; i++) {
    final player = roster[i];
    if (i > 0) {
      chips.add(const SizedBox(height: GameMapPlayersBar.chipGap));
    }
    final highlight =
        highlightPlayerId != null && highlightPlayerId == player.id;
    chips.add(
      GameMapPlayersBarChip(
        key: Key('$kGameMapPlayerChipKeyPrefix${player.id}'),
        name: player.displayName,
        score: scoreFormat.format(
          GameMapPlayersBar.powerScoreFor(game, player.id),
        ),
        swatchColor: _swatchColorFor(ownershipColors, player.id),
        minWidth: GameMapPlayersBar.chipMinWidth,
        nameStyle: highlight ? accentNameStyle : mutedNameStyle,
        scoreStyle: scoreStyle,
      ),
    );
  }
  return IgnorePointer(
    ignoring: true,
    child: Column(
      key: kGameMapPlayersBarKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: chips,
    ),
  );
}

Color _swatchColorFor(
  Map<String, (int r, int g, int b)> ownershipColors,
  String playerId,
) {
  final tuple = ownershipColors[playerId];
  if (tuple == null) {
    return EditorialMonoclePalette.muted;
  }
  return Color.fromRGBO(tuple.$1, tuple.$2, tuple.$3, 1.0);
}
