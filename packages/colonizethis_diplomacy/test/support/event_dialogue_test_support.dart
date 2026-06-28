import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared `Game` fixture for `event_dialogue_test.dart` and its split files.
///
/// Most dialogue tests construct a near-identical empty-world or
/// minimal-province game (orders phase) varying only by `turnNumber`,
/// `players`, optional region provinces, and a handful of optional
/// diplomacy / overture / minor-nation / tribe fields. This helper
/// centralizes that boilerplate on the shared [TestFixtures.minimalGame]
/// factory (Refs #3715) — the previous inline builder was equivalent to
/// `minimalGame` with the same orders-phase turn and empty-region defaults.
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
  return TestFixtures.minimalGame(
    id: id,
    turnNumber: turnNumber,
    players: players,
    oldWorld:
        oldWorldProvinces.isEmpty ? null : RegionData(provinces: oldWorldProvinces),
    newWorld:
        newWorldProvinces.isEmpty ? null : RegionData(provinces: newWorldProvinces),
    diplomacyRelations: diplomacyRelations,
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtureStates,
  );
}
