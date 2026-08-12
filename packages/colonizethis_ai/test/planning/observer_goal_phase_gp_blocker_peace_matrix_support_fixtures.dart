// Fixture families for observer-phase GP-blocker / peace-target matrix suites.
// Refs #3749, #4310 Slice D remainder.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String gp1 = 'gp1';
const String gp2 = 'gp2';
const String gp3 = 'gp3';
const String gp4 = 'gp4';
const String tribe1 = 'tribe1';
const String tribe2 = 'tribe2';
const String minor1 = 'minor1';
const String minor2 = 'minor2';

/// Game with NW provinces enumerated by `(id, ownerId)` pairs.
Game gameWithNwProvinces({
  required int turnNumber,
  required List<Province> nwProvinces,
  List<Player> players = const [
    Player(id: gp1, displayName: 'GP1', isHuman: false),
    Player(id: gp2, displayName: 'GP2', isHuman: false),
    Player(id: gp3, displayName: 'GP3', isHuman: false),
    Player(id: gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: tribe1, displayName: 'T1'),
    Tribe(id: tribe2, displayName: 'T2'),
  ],
  List<MinorNation> minorNations = const [
    MinorNation(id: minor1, displayName: 'M1'),
  ],
}) {
  return Game(
    id: 'g-2509-colonial-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP at the OW quota (10) with COLONIAL acquisition
/// targets visible — keeps `observerGoalPhaseFor` on COLONIAL so the
/// peace-target helper runs.
AIWorldSnapshot colonialSnapshot({
  required List<String> atWarWith,
  required List<String> invadableNw,
  List<String> adjacentNw = const [],
  String playerId = gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw.isEmpty
          ? (invadableNw.isEmpty ? const [tribe1] : const [])
          : adjacentNw,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Game with OW provinces enumerated by `(id, ownerId)` pairs.
Game gameWithOwProvinces({
  required int turnNumber,
  required List<Province> owProvinces,
  List<Player> players = const [
    Player(id: gp1, displayName: 'GP1', isHuman: false),
    Player(id: gp2, displayName: 'GP2', isHuman: false),
    Player(id: gp3, displayName: 'GP3', isHuman: false),
    Player(id: gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: tribe1, displayName: 'T1'),
    Tribe(id: tribe2, displayName: 'T2'),
  ],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-expand-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: RegionData(provinces: owProvinces),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP below the OW quota (8 / 10) so
/// `observerGoalPhaseFor` returns EXPAND when the game does not also
/// satisfy the COLONIAL-lite turn / NW-ownership preconditions.
AIWorldSnapshot expandSnapshot({
  required List<String> atWarWith,
  required List<String> invadableOw,
  int oldWorldProvincesOwned = 8,
  String playerId = gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Game scaffold with a configurable turn number and roster.
Game developGame({
  required int turnNumber,
  List<Player> players = const [
    Player(id: gp1, displayName: 'GP1', isHuman: false),
    Player(id: gp2, displayName: 'GP2', isHuman: false),
    Player(id: gp3, displayName: 'GP3', isHuman: false),
    Player(id: gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-develop-peace-target-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP **at** the OW quota (10) with an empty
/// colonial summary so `observerGoalPhaseFor` returns DEVELOP.
AIWorldSnapshot developSnapshot({
  required List<String> atWarWith,
  int oldWorldProvincesOwned = kObserverConquestMinOwProvincesPerGp,
  String playerId = gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Own-vs-partner OW roster fixture for `stalledBelowQuotaGpLeadPeaceTargets`.
Game ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  required String partnerId,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? invadableOwnerId,
  String? minorId,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|gp_own_$i',
        regionId: 'oldWorld',
        ownerId: 'gp_own',
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (invadableOwnerId != null)
      Province(
        id: 'oldWorld|frontier',
        regionId: 'oldWorld',
        ownerId: invadableOwnerId,
      ),
    if (minorId != null)
      const Province(
        id: 'oldWorld|minor_hold',
        regionId: 'oldWorld',
        ownerId: 'minor1',
      ),
  ];

  final players = <Player>[
    const Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: 'g-stalled-below-quota-${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

AIWorldSnapshot ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: 'gp_own',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
