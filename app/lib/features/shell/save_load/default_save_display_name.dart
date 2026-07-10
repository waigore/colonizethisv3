import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default typed save label: `{nation} - {leader} - {turn}`.
///
/// Nation is the first human [Player.displayName]. Leader resolves via
/// [defaultNamingConfig] `leaderVariants` matching [Player.leaderKey], else the
/// raw key, else `'Leader'`. SPEC/ui/save-game-name-dialog.md; issue #3959.
String defaultSaveDisplayName(Game game) {
  Player? human;
  for (final player in game.players) {
    if (player.isHuman) {
      human = player;
      break;
    }
  }
  final nation = human?.displayName ?? 'Nation';
  final leader = _leaderDisplayName(human?.leaderKey);
  final turn = game.worldState.turnState.turnNumber;
  return '$nation - $leader - $turn';
}

String _leaderDisplayName(String? leaderKey) {
  if (leaderKey == null || leaderKey.isEmpty) {
    return 'Leader';
  }
  for (final gp in defaultNamingConfig.greatPowers) {
    for (final variant in gp.leaderVariants) {
      if (variant.leaderKey == leaderKey) {
        return variant.name;
      }
    }
  }
  return leaderKey;
}
