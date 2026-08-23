/// COLONIAL phase-planner Game / snapshot builders (Refs #3967 / #4602 Slice E).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'colonial_phase_planner_test_support_core.dart';

/// Game scaffold for COLONIAL-phase / lite destination-filter pins.
///
/// New World provinces, players, tribes, and minors are passed in so each
/// test can shape ownership independently. Old World defaults to empty
/// because most planners do not query OW state for the destination filter
/// (the OW summary is read only for the outer quota gate).
Game buildColonialPhaseGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  List<Army> armies = const [],
  Map<String, String> resourceByTileKey = const {},
  TileMapState tileState = const TileMapState(),
  List<Player> players = kColonialPhaseDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
  String gameIdPrefix = 'g-2509-colonial-phase-planner',
  String? gameId,
}) {
  return Game(
    id: gameId ?? '$gameIdPrefix-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      armies: armies,
      resourceByTileKey: resourceByTileKey,
      tileState: tileState,
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
  );
}

/// Snapshot tuned for COLONIAL / COLONIAL-lite destination pins.
///
/// Own OW defaults to 10 (at quota). Tests shape `atWarWith`,
/// `invadableNw`, `invadableOw`, adjacent / preferred colonial lists,
/// and `oldWorldProvincesOwned` to exercise specific priority arms.
AIWorldSnapshot buildColonialPhaseSnapshot({
  List<String> atWarWith = const [],
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  List<String> adjacentNw = const [],
  List<String> preferredColonial = const [],
  int oldWorldProvincesOwned = 10,
  String playerId = kColonialPhaseGp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw,
      preferredColonialTargetFactionIdsSorted: preferredColonial,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Below-quota lock-recovery snapshot used by Path E waiver pins.
AIWorldSnapshot buildLockRecoveryBelowQuotaSnapshot({
  required List<String> invadableNw,
}) {
  return AIWorldSnapshot(
    playerId: kColonialPhaseGp1,
    threats: const ThreatSummary(atWarWith: [kColonialPhaseTribe1]),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 9,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: const [],
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      newWorldProvincesOwned: 0,
    ),
    economy: const EconomySummary(treasury: 0),
    relations: const {},
  );
}

/// COLONIAL-lite naval Game scaffold (turn 125, three-GP roster).
Game buildColonialLiteNavalGame({
  int turnNumber = 125,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = kColonialLiteNavalDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    newWorldProvinces: newWorldProvinces,
    oldWorldProvinces: oldWorldProvinces,
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    gameIdPrefix: 'g-2509-colonial-lite-naval',
  );
}

/// COLONIAL-lite naval snapshot (OW owned defaults to 9).
AIWorldSnapshot buildColonialLiteNavalSnapshot({
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  List<String> atWarWith = const [],
  int oldWorldProvincesOwned = 9,
  String playerId = kColonialPhaseGp1,
}) {
  return buildColonialPhaseSnapshot(
    atWarWith: atWarWith,
    invadableNw: invadableNw,
    invadableOw: invadableOw,
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    playerId: playerId,
  );
}

/// COLONIAL-lite overture Game scaffold (empty regions + overture rows).
Game buildColonialLiteOvertureGame({
  int turnNumber = 125,
  List<Player> players = kColonialLiteOvertureDefaultPlayers,
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
    gameIdPrefix: 'g-2509-colonial-lite-overtures',
  );
}

/// COLONIAL-lite overture snapshot (OW owned defaults to 9).
AIWorldSnapshot buildColonialLiteOvertureSnapshot({
  List<String> adjacentNw = const [],
  List<String> preferredColonial = const [],
  int oldWorldProvincesOwned = 9,
  String playerId = kColonialPhaseGp1,
}) {
  return buildColonialPhaseSnapshot(
    adjacentNw: adjacentNw,
    preferredColonial: preferredColonial,
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    playerId: playerId,
  );
}

/// COLONIAL civilian Game scaffold (provinces + units + tile resources).
Game buildColonialCivilianGame({
  required List<Province> provinces,
  required List<Unit> owUnits,
  List<Unit> nwUnits = const [],
  Map<String, String> resourceByTileKey = const {},
  TileMapState tileState = const TileMapState(),
  List<Player> players = kColonialCivilianDefaultPlayers,
}) {
  final byRegion = <String, List<Province>>{};
  for (final province in provinces) {
    byRegion.putIfAbsent(province.regionId, () => <Province>[]).add(province);
  }
  return buildColonialPhaseGame(
    turnNumber: 132,
    oldWorldProvinces: byRegion[kOldWorldRegionId] ?? const [],
    newWorldProvinces: byRegion[kNewWorldRegionId] ?? const [],
    oldWorldUnits: owUnits,
    newWorldUnits: nwUnits,
    resourceByTileKey: resourceByTileKey,
    tileState: tileState,
    players: players,
    gameId: 'g-2509-colonial-phase-planner-civilian',
  );
}

/// Minimal snapshot for COLONIAL civilian in-module pins.
AIWorldSnapshot buildColonialCivilianSnapshot({
  String playerId = kColonialPhaseGp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

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
