// Shared helpers for pre-combat index scenario tables (Refs #4196 slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_resolver_test_support.dart';

const preCombatIndexOldWorldRegionId = 'oldWorld';

Army preCombatIndexArmy(
  String id, {
  required String ownerId,
  String stationedProvinceId = '$preCombatIndexOldWorldRegionId|p1',
  bool isHomeArmy = false,
}) => Army(
  id: id,
  ownerId: ownerId,
  regionId: preCombatIndexOldWorldRegionId,
  stationedProvinceId: stationedProvinceId,
  regimentUnitIds: const [],
  isHomeArmy: isHomeArmy,
);

Game preCombatIndexFixtureGame({
  List<Player> players = const [
    Player(id: 'p1', displayName: 'P1', isHuman: true),
    Player(id: 'p2', displayName: 'P2', isHuman: false),
  ],
  List<Army> armies = const [],
  RegionData? oldWorld,
}) => preCombatIndexGame(players: players, armies: armies, oldWorld: oldWorld);
