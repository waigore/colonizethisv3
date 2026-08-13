/// Shared Game shell for civilian-work scoring twins (Refs #4368 Slice C).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

const String civilianWorkScoringPlayerId = 'gp1';

Game civilianWorkScoringGame({
  String playerDisplayName = 'GP',
  Map<String, String> resourceByTileKey = const {},
  Map<String, int> improvementByTile = const {},
  String? capitalProvinceId,
  List<Player> rivals = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<Unit> oldWorldUnits = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(units: oldWorldUnits),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: [
      Player(
        id: civilianWorkScoringPlayerId,
        displayName: playerDisplayName,
        isHuman: false,
        capitalProvinceId: capitalProvinceId,
      ),
      ...rivals,
    ],
    diplomacyRelations: diplomacyRelations,
  );
}
