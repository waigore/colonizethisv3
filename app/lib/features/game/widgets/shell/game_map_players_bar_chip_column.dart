part of 'game_map_players_bar.dart';

extension _GameMapPlayersBarChipColumn on GameMapPlayersBar {
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

  Widget _buildChipColumn(BuildContext context) {
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
      final highlight = highlightPlayerId != null &&
          highlightPlayerId == player.id;
      chips.add(
        _PlayerChip(
          key: Key('$kGameMapPlayerChipKeyPrefix${player.id}'),
          name: player.displayName,
          score: scoreFormat.format(GameMapPlayersBar.powerScoreFor(game, player.id)),
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
}
