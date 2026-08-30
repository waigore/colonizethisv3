/// Human player-id set for army / fleet / civilian map-marker inclusion.
/// SPEC/ui/map-widget.md. Refs #4654.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

Set<String> humanPlayerIds(Game game) {
  return {
    for (final player in game.players)
      if (player.isHuman) player.id,
  };
}
