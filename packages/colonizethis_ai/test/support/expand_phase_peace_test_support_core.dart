/// Core OW Game + snapshot builders for expand-peace pins (Refs #3967 / #4291).
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default active GP id used by most expand-peace pins.
const String kExpandPeaceGpOwn = 'gp_own';

/// Default partner / peer GP id for peer-stalled peace pins.
const String kExpandPeaceGpPartner = 'gp_partner';

/// Builds the minimal [AIWorldSnapshot] shape shared by expand-peace pins.
AIWorldSnapshot ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  String playerId = kExpandPeaceGpOwn,
  List<String> invadableProvinceIdsSorted = const [],
  List<String> adjacentOwnerFactionIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
      adjacentOwnerFactionIdsSorted: adjacentOwnerFactionIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Parameterized OW Game builder used by critical / distraction-style pins.
///
/// [ownProvinces] are auto-generated under [ownPlayerId]. Additional OW
/// holdings come from [otherProvinceOwners]. When [autoMinorHomeProvinces]
/// is true, each id in [minorIds] also gets a single `{id}_home` province
/// (critical-peace shape); distraction pins pass explicit province lists
/// instead and leave this false.
Game buildExpandPeaceGame({
  required int ownProvinces,
  String ownPlayerId = kExpandPeaceGpOwn,
  Map<String, List<String>> otherProvinceOwners = const {},
  List<String> gpIds = const [],
  List<String> minorIds = const [],
  bool autoMinorHomeProvinces = false,
  List<String> tribeIds = const [],
  List<String> atWarFactionIds = const [],
  List<Army> armies = const [],
  int turnNumber = 60,
  String gameIdPrefix = 'g-expand-peace',
  String? gameId,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    for (final entry in otherProvinceOwners.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
    if (autoMinorHomeProvinces)
      for (final minorId in minorIds)
        Province(
          id: 'oldWorld|${minorId}_home',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
  ];

  return Game(
    id: gameId ?? '$gameIdPrefix-own$ownProvinces-${atWarFactionIds.join("-")}',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      for (final id in gpIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final id in minorIds) MinorNation(id: id, displayName: id),
    ],
    tribes: [for (final id in tribeIds) Tribe(id: id, displayName: id)],
    diplomacyRelations: [
      for (final id in atWarFactionIds)
        DiplomacyRelation(
          factionId1: ownPlayerId,
          factionId2: id,
          state: RelationState.atWar,
          score: 30,
        ),
    ],
  );
}

