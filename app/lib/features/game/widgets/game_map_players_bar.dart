import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../flame/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;

/// Floating column of per–Great-Power chips at the top-right of the in-game
/// map stack.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Players bar. Issue #2861 S6
/// (game-screen players bar). Hidden on narrow viewports per
/// `SPEC/ui/mobile-adaptation.md` / issue #2870; this widget renders the
/// wide-only baseline.
///
/// The chip column is non-interactive: pointer events pass through to the
/// map layer beneath. All colours resolve from
/// [EditorialMonoclePalette]; the per-player swatch matches the canonical
/// map ownership tint via [factionOwnershipColorMapForOldWorld].
class GameMapPlayersBar extends StatelessWidget {
  const GameMapPlayersBar({super.key, required this.game});

  final Game game;

  /// Vertical inset from the top of the map stack to the first chip row
  /// (mockup `top:78px`, sits below the 36 + 34 + 8 dp chrome band).
  static const double topInset = 78;

  /// Horizontal inset from the right edge of the map stack.
  static const double rightInset = 6;

  /// Vertical gap between consecutive chip rows.
  static const double chipGap = 3;

  /// Minimum width for each chip row so 1- and 4-digit scores line up.
  static const double chipMinWidth = 80;

  /// Returns the deterministic, GP-only player roster used by the bar.
  ///
  /// Visible for tests and integration. Tribes/minor-nation entries are
  /// excluded (the chip column tracks Great Powers only); the result is
  /// sorted by [Player.id] ascending so chip order is stable across builds.
  static List<Player> greatPowerRoster(Game game) {
    final tribeIds = <String>{for (final tribe in game.tribes) tribe.id};
    final roster = game.players
        .where((player) => !tribeIds.contains(player.id))
        .toList(growable: false);
    return List<Player>.from(roster)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Counts Old World provinces currently owned by [playerId]; used as the
  /// chip's score (military-victory progress, threshold 31+).
  static int oldWorldProvinceCountFor(Game game, String playerId) {
    var count = 0;
    for (final province in game.worldState.oldWorld.provinces) {
      if (province.ownerId == playerId) {
        count += 1;
      }
    }
    return count;
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

  @override
  Widget build(BuildContext context) {
    final roster = greatPowerRoster(game);
    if (roster.isEmpty) {
      return const SizedBox.shrink();
    }
    final ownershipColors = factionOwnershipColorMapForOldWorld(game);
    final scoreFormat = NumberFormat.decimalPattern('en_US');
    final theme = Theme.of(context);
    final nameStyle = (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 10))
        .copyWith(
          color: EditorialMonoclePalette.muted,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        );
    final scoreStyle = (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 9))
        .copyWith(
          color: EditorialMonoclePalette.accentDim,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          fontSize: 9,
        );
    final chips = <Widget>[];
    for (var i = 0; i < roster.length; i++) {
      final player = roster[i];
      if (i > 0) {
        chips.add(const SizedBox(height: chipGap));
      }
      chips.add(
        _PlayerChip(
          key: Key('$kGameMapPlayerChipKeyPrefix${player.id}'),
          name: player.displayName,
          score: scoreFormat.format(
            oldWorldProvinceCountFor(game, player.id),
          ),
          swatchColor: _swatchColorFor(ownershipColors, player.id),
          minWidth: chipMinWidth,
          nameStyle: nameStyle,
          scoreStyle: scoreStyle,
        ),
      );
    }
    return Positioned(
      key: kGameMapPlayersBarKey,
      top: topInset,
      right: rightInset,
      child: IgnorePointer(
        ignoring: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: chips,
        ),
      ),
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
