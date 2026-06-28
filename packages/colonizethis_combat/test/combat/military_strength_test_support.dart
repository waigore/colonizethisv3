import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared `Game` fixture and unit shorthand for `military_strength_test.dart`.
///
/// Almost every test in that file constructs a `Game` with a fixed orders-phase
/// `WorldState`, then varies units in the Old/New World and the faction
/// composition (Great Powers vs Minor Nations vs Tribes). This helper
/// centralizes that boilerplate so tests focus on the units and assertions.
///
/// Refs waigore/colonizethis#2216 (consolidate duplicated test setup).
Game militaryStrengthGame({
  String id = 'g1',
  int turnNumber = 1,
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  List<Player> players = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(units: oldWorldUnits),
      newWorld: RegionData(units: newWorldUnits),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Shorthand for the standard test player France (Great Power, human).
const franceGreatPower = Player(
  id: 'france',
  displayName: 'France',
  isHuman: true,
);

/// Shorthand `Unit` constructor for military-strength tests. Defaults match the
/// shape used throughout `military_strength_test.dart` (medals 0).
Unit testUnit({
  required String id,
  required String type,
  String ownerId = 'france',
  String locationProvinceId = 'paris',
  int medals = 0,
}) => Unit(
  id: id,
  type: type,
  ownerId: ownerId,
  locationProvinceId: locationProvinceId,
  medals: medals,
);
