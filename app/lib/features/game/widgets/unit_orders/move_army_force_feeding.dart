// Post-extraction forces-food preview for move army / combat soft warns (#4242).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

ForceFeedingSnapshot humanForcesFeedingPreview({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  Orders draftOrders = const Orders(),
}) {
  final regimentCounts = regimentTypeCountsForPlayer(
    game.worldState,
    humanPlayerId,
  );
  final shipCounts = shipTypeCountsForPlayer(
    game.worldState,
    humanPlayerId,
  );
  return forcesFeedingForPlayer(
    game: game,
    topology: topology,
    playerId: humanPlayerId,
    foodCounts: MilitaryNavyFoodCounts(
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    ),
    inputs: economyPreviewInputs(currentOrders: draftOrders),
  );
}
