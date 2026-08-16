import 'package:colonizethis_data/colonizethis_data.dart'
    show kMilitaryVictoryOldWorldProvinceThreshold;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Glanceable Old World province race for the `MAP10001` tab-bar chip.
///
/// SPEC: `SPEC/ui/components/old-world-race-chip.md`. Refs #4451.
class OldWorldRaceSnapshot {
  const OldWorldRaceSnapshot({
    required this.focusPlayerId,
    required this.focusCount,
    required this.threshold,
    this.rivalLeaderName,
    this.rivalLeaderCount,
  });

  final String focusPlayerId;
  final int focusCount;
  final int threshold;
  final String? rivalLeaderName;
  final int? rivalLeaderCount;

  bool get rivalIsAhead =>
      rivalLeaderName != null &&
      rivalLeaderCount != null &&
      rivalLeaderCount! > focusCount;

  static List<Player> greatPowerPlayers(Game game) {
    final tribeIds = <String>{for (final tribe in game.tribes) tribe.id};
    return game.players
        .where((player) => !tribeIds.contains(player.id))
        .toList(growable: false);
  }

  static String? leadingPlayerId(Game game) {
    final gps = List<Player>.from(greatPowerPlayers(game));
    if (gps.isEmpty) {
      return null;
    }
    gps.sort((a, b) {
      final owCompare = oldWorldProvinceCountOwnedBy(
        game,
        b.id,
      ).compareTo(oldWorldProvinceCountOwnedBy(game, a.id));
      if (owCompare != 0) {
        return owCompare;
      }
      return a.displayName.compareTo(b.displayName);
    });
    return gps.first.id;
  }

  static OldWorldRaceSnapshot fromGame({
    required Game game,
    required String focusPlayerId,
  }) {
    final gps = greatPowerPlayers(game);
    final threshold = kMilitaryVictoryOldWorldProvinceThreshold;
    final focusCount = oldWorldProvinceCountOwnedBy(game, focusPlayerId);

    Player? rival;
    var rivalCount = -1;
    for (final player in gps) {
      if (player.id == focusPlayerId) {
        continue;
      }
      final count = oldWorldProvinceCountOwnedBy(game, player.id);
      if (rival == null || count > rivalCount) {
        rival = player;
        rivalCount = count;
        continue;
      }
      if (count == rivalCount &&
          player.displayName.compareTo(rival.displayName) < 0) {
        rival = player;
      }
    }

    final showRival = rival != null && rivalCount > focusCount;
    return OldWorldRaceSnapshot(
      focusPlayerId: focusPlayerId,
      focusCount: focusCount,
      threshold: threshold,
      rivalLeaderName: showRival ? rival.displayName : null,
      rivalLeaderCount: showRival ? rivalCount : null,
    );
  }
}
