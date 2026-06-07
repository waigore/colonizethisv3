import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';


/// Leader combat bonus for a faction. GPs use Player.leaderKey; minors/tribes
/// get 1.0. SPEC/game/leader-bonuses.md.
double leaderBonusForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  return leaderCombatBonusMultiplier(player?.leaderKey);
}

/// Fallback general medals when no assignable general exists for a side.
/// SPEC/program/combat-resolution.md §3; SPEC/game/military-generals.md.
int fallbackGeneralMedalsFromLeader(Game game, String factionId) {
  final leaderMult = leaderBonusForFaction(game, factionId);
  if (leaderMult >= 1.25) return 4;
  if (leaderMult >= 1.20) return 3;
  if (leaderMult >= 1.15) return 2;
  if (leaderMult >= 1.10) return 1;
  return 0;
}
