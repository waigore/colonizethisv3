import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared `Game` fixture for `event_dialogue_test.dart` and its split files.
///
/// Most dialogue tests construct a near-identical empty-world or
/// minimal-province game (orders phase) varying only by `turnNumber`,
/// `players`, optional region provinces, and a handful of optional
/// diplomacy / overture / minor-nation / tribe fields. This helper
/// centralizes that boilerplate.
///
/// Refs waigore/colonizethis#2216 (consolidate duplicated test setup).
Game dialogueGame({
  String id = 'g1',
  int turnNumber = 1,
  required List<Player> players,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<OvertureState> overtureStates = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: oldWorldProvinces.isEmpty
          ? const RegionData()
          : RegionData(provinces: oldWorldProvinces),
      newWorld: newWorldProvinces.isEmpty
          ? const RegionData()
          : RegionData(provinces: newWorldProvinces),
    ),
    players: players,
    diplomacyRelations: diplomacyRelations,
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtureStates,
  );
}
