import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// Leader combat bonus for a faction. GPs use Player.leaderKey; minors/tribes
/// get 1.0. SPEC/game/leader-bonuses.md.
double leaderBonusForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  return leaderCombatBonusMultiplier(player?.leaderKey);
}
