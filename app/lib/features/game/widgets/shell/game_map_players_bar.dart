import 'package:colonizethis_logic/colonizethis_logic.dart'
    show greatPowerPowerScore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'game_map_players_bar_chip_column.dart';

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

  @override
  Widget build(BuildContext context) {
    final column = buildGameMapPlayersBarChipColumn(
      context: context,
      game: game,
      highlightPlayerId: highlightPlayerId,
    );
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
