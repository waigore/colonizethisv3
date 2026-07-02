import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures.dart';

/// Shared `Game` fixture for `event_dialogue_test.dart` and its split files.
///
/// Routes through [diplomacyGame] so dossier dialogue tests share the same
/// builder defaults as the rest of the diplomacy suite (Refs #3837).
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
  return diplomacyGame(
    id: id,
    turnNumber: turnNumber,
    players: players,
    oldWorld: oldWorldProvinces.isEmpty
        ? null
        : RegionData(provinces: oldWorldProvinces),
    newWorld: newWorldProvinces.isEmpty
        ? null
        : RegionData(provinces: newWorldProvinces),
    diplomacyRelations: diplomacyRelations,
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtureStates,
  );
}
