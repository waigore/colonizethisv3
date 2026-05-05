import 'package:colonizethis_models/colonizethis_models.dart';

typedef DebugCommandResult = ({Game? game, String message});

Player? findPlayerById(Game game, String playerId) {
  for (final candidate in game.players) {
    if (candidate.id == playerId) {
      return candidate;
    }
  }
  return null;
}
