import 'package:colonizethis_logic/colonizethis_logic.dart'
    show greatPowerPowerScore;
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../flame/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;

/// Floating column of per–Great-Power chips on the in-game map stack.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Players bar. Issue #3898.
class GameMapPlayersBar extends StatelessWidget {
  const GameMapPlayersBar({
    super.key,
    required this.game,
    this.highlightPlayerId,
    this.narrow = false,
    this.embedded = false,
    this.rightInset,
    this.topInsetOverride,
  });

  final Game game;
  final String? highlightPlayerId;
  final bool narrow;
  final bool embedded;
  final double? rightInset;
  final double? topInsetOverride;

  static const double wideTopInset = 78;
  static const double narrowTopInset = 56;
  static const double rightInsetDefault = 6;
  static const double chipGap = 3;
  static const double chipMinWidth = 88;
  static const double narrowStackGap = 4;

  static List<Player> greatPowerRoster(Game game) {
    final tribeIds = <String>{for (final tribe in game.tribes) tribe.id};
    final roster = game.players
        .where((player) => !tribeIds.contains(player.id))
        .toList(growable: false);
    return List<Player>.from(roster)
      ..sort((a, b) {
        final scoreCompare = greatPowerPowerScore(
          game,
          b.id,
        ).compareTo(greatPowerPowerScore(game, a.id));
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return a.id.compareTo(b.id);
      });
  }

  static int powerScoreFor(Game game, String playerId) =>
      greatPowerPowerScore(game, playerId);

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
    final roster = greatPowerRoster(game);
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
        chips.add(const SizedBox(height: chipGap));
      }
      final highlight = highlightPlayerId != null &&
          highlightPlayerId == player.id;
      chips.add(
        _PlayerChip(
          key: Key('$kGameMapPlayerChipKeyPrefix${player.id}'),
          name: player.displayName,
          score: scoreFormat.format(powerScoreFor(game, player.id)),
          swatchColor: _swatchColorFor(ownershipColors, player.id),
          minWidth: chipMinWidth,
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

  @override
  Widget build(BuildContext context) {
    final column = _buildChipColumn(context);
    if (embedded) {
      return column;
    }
    final top = topInsetOverride ?? (narrow ? narrowTopInset : wideTopInset);
    final right = rightInset ?? rightInsetDefault;
    return Positioned(
      top: top,
      right: right,
      child: column,
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    super.key,
    required this.name,
    required this.score,
    required this.swatchColor,
    required this.minWidth,
    required this.nameStyle,
    required this.scoreStyle,
  });

  final String name;
  final String score;
  final Color swatchColor;
  final double minWidth;
  final TextStyle nameStyle;
  final TextStyle scoreStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            EditorialMonoclePalette.surface,
            EditorialMonoclePalette.bgDeep,
          ],
        ),
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: swatchColor,
                  border: Border.all(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  style: nameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                score,
                style: scoreStyle,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
