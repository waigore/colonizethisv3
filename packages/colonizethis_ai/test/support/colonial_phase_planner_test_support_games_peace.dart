/// COLONIAL peace Game / snapshot builders (Refs #3967 / #4602 Slice E).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'colonial_phase_planner_test_support_core.dart';
import 'colonial_phase_planner_test_support_games.dart';

/// Builds OW provinces owned by [ownerId] for COLONIAL peace quota pins.
List<Province> buildColonialPeaceOwProvincesForOwner(
  String ownerId, {
  int count = kColonialPeaceOwProvincesAtQuota,
}) {
  return [
    for (var i = 0; i < count; i++)
      Province(
        id: 'oldWorld|${ownerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownerId,
      ),
  ];
}

/// Default OW quota provinces for the four-GP COLONIAL peace roster.
List<Province> buildColonialPeaceDefaultOwQuotaProvinces({
  Map<String, int> perGpOwCounts = const {},
}) {
  return [
    for (final gp in const [
      kColonialPhaseGp1,
      kColonialPhaseGp2,
      kColonialPhaseGp3,
      kColonialPhaseGp4,
    ])
      ...buildColonialPeaceOwProvincesForOwner(
        gp,
        count: perGpOwCounts[gp] ?? kColonialPeaceOwProvincesAtQuota,
      ),
  ];
}

/// COLONIAL peace Game scaffold (four-GP roster at OW quota by default).
Game buildColonialPeaceGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province>? oldWorldProvinces,
  Map<String, int> perGpOwCounts = const {},
  List<Player> players = kColonialPeaceDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    newWorldProvinces: newWorldProvinces,
    oldWorldProvinces:
        oldWorldProvinces ??
        buildColonialPeaceDefaultOwQuotaProvinces(perGpOwCounts: perGpOwCounts),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    gameIdPrefix: 'g-2509-colonial-phase-planner-peace',
  );
}

/// Snapshot tuned for COLONIAL peace pins (OW owned defaults to 10).
AIWorldSnapshot buildColonialPeaceSnapshot({
  required List<String> atWarWith,
  List<String> invadableNw = const [],
  String playerId = kColonialPhaseGp1,
}) {
  return buildColonialPhaseSnapshot(
    atWarWith: atWarWith,
    invadableNw: invadableNw,
    playerId: playerId,
  );
}
