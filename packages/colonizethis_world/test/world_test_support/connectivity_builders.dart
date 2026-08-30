import 'package:colonizethis_models/colonizethis_models.dart';

/// Orders-phase [WorldState] with optional region payloads.
WorldState ordersPhaseWorldState({
  int turnNumber = 1,
  RegionData? oldWorld,
  RegionData? newWorld,
  TileMapState? tileState,
  Map<String, String>? portsByProvinceSeaboard,
  List<Fleet>? fleets,
}) {
  return WorldState(
    turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
    oldWorld: oldWorld ?? const RegionData(),
    newWorld: newWorld ?? const RegionData(),
    tileState: tileState ?? const TileMapState(),
    portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
    fleets: fleets ?? const [],
  );
}

/// Orders-phase [Game] for connectivity / blockade scenario pins (Refs #3968).
Game ordersPhaseGame({
  String id = 'g1',
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Fleet> fleets = const [],
  List<Player> players = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  TileMapState? tileState,
  Map<String, String> portsByProvinceSeaboard = const {},
  int turnNumber = 1,
}) {
  return Game(
    id: id,
    worldState: ordersPhaseWorldState(
      turnNumber: turnNumber,
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      fleets: fleets,
      tileState: tileState,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: diplomacyRelations,
  );
}
