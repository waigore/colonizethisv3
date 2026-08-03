/// Shared fixtures for EXPAND-regime peace unit pins (Refs #3967 / #3997).
///
/// Owns [ownSnapshot], [buildOwnVsPartnerExpandPeaceGame], and the duplicated
/// Game builders ([buildCriticalExpandPeaceGame],
/// [buildDistractionExpandPeaceGame], [buildZeroRegimentExpandPeaceGame],
/// [buildPeerExpandPeaceGame]) so per-decider `*_peace_test.dart` files and
/// Phase-8 case modules keep only assertions and decider-specific constants.
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

/// Critical-peace Game builder (own + rival province maps + minors/tribes).
Game buildCriticalExpandPeaceGame({
  required int ownProvinces,
  Map<String, List<String>> gpRivalProvincesById = const {},
  List<String> minorIds = const [],
  List<String> tribeIds = const [],
  List<String> atWarFactionIds = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
}) {
  return buildExpandPeaceGame(
    ownProvinces: ownProvinces,
    ownPlayerId: ownPlayerId,
    otherProvinceOwners: gpRivalProvincesById,
    gpIds: gpRivalProvincesById.keys.toList(growable: false),
    minorIds: minorIds,
    autoMinorHomeProvinces: true,
    tribeIds: tribeIds,
    atWarFactionIds: atWarFactionIds,
    turnNumber: 60,
    gameId:
        'g-2509-critical-peace-canonical-'
        'own$ownProvinces-${gpRivalProvincesById.keys.join("-")}',
  );
}

/// Stalled-distraction Game builder (explicit province owners + GP roster).
Game buildDistractionExpandPeaceGame({
  required int ownProvinces,
  Map<String, List<String>> provinceOwners = const {},
  List<String> minors = const [],
  List<String> tribes = const [],
  List<String> gps = const [],
  List<String> atWarFactionIds = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
}) {
  return buildExpandPeaceGame(
    ownProvinces: ownProvinces,
    ownPlayerId: ownPlayerId,
    otherProvinceOwners: provinceOwners,
    gpIds: gps,
    minorIds: minors,
    tribeIds: tribes,
    atWarFactionIds: atWarFactionIds,
    turnNumber: 70,
    gameIdPrefix: 'g-2509-stalled-distraction-canonical',
  );
}

/// Zero-regiment survival Game builder (home armies + enemy GP roster).
Game buildZeroRegimentExpandPeaceGame({
  required int ownProvinces,
  required int ownRegimentCount,
  required List<String> enemyGpIds,
  required int enemyRegimentCount,
  List<String> minorIds = const [],
  List<String> tribeIds = const [],
  List<String> atWarMinorIds = const [],
  List<String> atWarTribeIds = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
}) {
  final provinces = <Province>[
    Province(
      id: 'oldWorld|${ownPlayerId}_home',
      regionId: 'oldWorld',
      ownerId: ownPlayerId,
    ),
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    for (final enemyId in enemyGpIds)
      Province(
        id: 'oldWorld|${enemyId}_home',
        regionId: 'oldWorld',
        ownerId: enemyId,
      ),
    for (final minorId in minorIds)
      Province(
        id: 'oldWorld|${minorId}_home',
        regionId: 'oldWorld',
        ownerId: minorId,
      ),
  ];

  final armies = <Army>[
    Army(
      id: homeArmyIdFor(ownPlayerId),
      ownerId: ownPlayerId,
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|${ownPlayerId}_home',
      regimentUnitIds: List<String>.unmodifiable(
        List<String>.generate(
          ownRegimentCount,
          (i) => 'u_${ownPlayerId}_${i + 1}',
        ),
      ),
      isHomeArmy: true,
    ),
    for (final enemyId in enemyGpIds)
      Army(
        id: homeArmyIdFor(enemyId),
        ownerId: enemyId,
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|${enemyId}_home',
        regimentUnitIds: List<String>.unmodifiable(
          List<String>.generate(
            enemyRegimentCount,
            (i) => 'u_${enemyId}_${i + 1}',
          ),
        ),
        isHomeArmy: true,
      ),
  ];

  final relations = <DiplomacyRelation>[
    for (final enemyId in enemyGpIds)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: enemyId,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final minorId in atWarMinorIds)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final tribeId in atWarTribeIds)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: tribeId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-zero-regiment-gp-peace-canonical-'
        '${ownProvinces}_${ownRegimentCount}_${enemyRegimentCount}_'
        '${enemyGpIds.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      for (final enemyId in enemyGpIds)
        Player(id: enemyId, displayName: enemyId.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final minorId in minorIds)
        MinorNation(id: minorId, displayName: minorId),
    ],
    tribes: [
      for (final tribeId in tribeIds) Tribe(id: tribeId, displayName: tribeId),
    ],
    diplomacyRelations: relations,
  );
}

/// Below-quota peer-GP Game builder (own vs partner province counts).
Game buildPeerExpandPeaceGame({
  required int ownProvinces,
  required int partnerProvinces,
  String ownPlayerId = kExpandPeaceGpOwn,
  String partnerPlayerId = kExpandPeaceGpPartner,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerPlayerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (minorId != null)
      for (var i = 1; i <= minorProvinces; i++)
        Province(
          id: 'oldWorld|${minorId}_$i',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: partnerPlayerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: minorId,
        state: RelationState.atWar,
        score: 10,
      ),
  ];

  return Game(
    id:
        'g-2509-below-quota-peer-gp-peace-canonical-'
        '${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      Player(id: partnerPlayerId, displayName: 'GP_PARTNER', isHuman: false),
      if (extraGpId != null)
        Player(
          id: extraGpId,
          displayName: extraGpId.toUpperCase(),
          isHuman: false,
        ),
    ],
    minorNations: [
      if (minorId != null) MinorNation(id: minorId, displayName: minorId),
    ],
    diplomacyRelations: relations,
  );
}

/// Sole-GP / unwinnable-frontier / critical-hold Game builder used by the
/// expand peace matrix sole-GP case modules and the sole-GP / critical
/// OW-hold peace pins (Refs #3997 fixture consolidation).
///
/// Distinct from [buildPeerExpandPeaceGame]: preserves turn 80, relation
/// score `30` on minor arms, optional [extraInvadableMinorOwnerId]
/// province, and optional partner-owned [invadablePartnerProvince] at
/// `oldWorld|invadable_partner` (GP-only frontier carve-out pins).
Game buildOwnVsPartnerExpandPeaceGame({
  required int ownProvinces,
  required int partnerProvinces,
  String partnerId = kExpandPeaceGpPartner,
  String ownPlayerId = kExpandPeaceGpOwn,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  String? extraInvadableMinorOwnerId,
  bool invadablePartnerProvince = false,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
  String? gameId,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
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
    if (minorId != null)
      for (var i = 1; i <= minorProvinces; i++)
        Province(
          id: 'oldWorld|${minorId}_$i',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
    if (extraInvadableMinorOwnerId != null)
      Province(
        id: 'oldWorld|invadable_minor',
        regionId: 'oldWorld',
        ownerId: extraInvadableMinorOwnerId,
      ),
    if (invadablePartnerProvince)
      Province(
        id: 'oldWorld|invadable_partner',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
  ];

  final players = <Player>[
    Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
    if (extraInvadableMinorOwnerId != null)
      MinorNation(
        id: extraInvadableMinorOwnerId,
        displayName: extraInvadableMinorOwnerId,
      ),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: gameId ?? 'g-unwinnable-sole-gp-${ownProvinces}_vs_$partnerProvinces',
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

/// Minor / tribe ids used by default-start and near-quota peace pins.
const Set<String> kExpandPeaceDefaultStartKnownMinors = {
  'minor_m1',
  'minor_m2',
};
const Set<String> kExpandPeaceDefaultStartKnownTribes = {'tribe_t1'};

/// Default-start / near-quota Game builder (`owOwners` map shape).
Game buildDefaultStartNearQuotaExpandPeaceGame({
  required Map<String, int> owOwners,
  required List<String> atWarPartners,
  bool atWarWithExtraGp = true,
  String ownPlayerId = kExpandPeaceGpOwn,
  Set<String> knownMinors = kExpandPeaceDefaultStartKnownMinors,
  Set<String> knownTribes = kExpandPeaceDefaultStartKnownTribes,
}) {
  final provinces = <Province>[
    for (final entry in owOwners.entries)
      for (var i = 1; i <= entry.value; i++)
        Province(
          id: 'oldWorld|${entry.key}_$i',
          regionId: 'oldWorld',
          ownerId: entry.key,
        ),
  ];

  final ownerAndPartnerIds = <String>{...owOwners.keys, ...atWarPartners};

  final players = <Player>[
    Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
    for (final id in ownerAndPartnerIds)
      if (id != ownPlayerId &&
          !knownMinors.contains(id) &&
          !knownTribes.contains(id))
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
  ];

  final minorNations = <MinorNation>[
    for (final id in ownerAndPartnerIds)
      if (knownMinors.contains(id)) MinorNation(id: id, displayName: id),
  ];

  final tribes = <Tribe>[
    for (final id in ownerAndPartnerIds)
      if (knownTribes.contains(id)) Tribe(id: id, displayName: id),
  ];

  final relations = <DiplomacyRelation>[
    for (final partner in atWarPartners)
      if (atWarWithExtraGp || players.any((p) => p.id == partner))
        DiplomacyRelation(
          factionId1: ownPlayerId,
          factionId2: partner,
          state: RelationState.atWar,
          score: 30,
        ),
  ];

  return Game(
    id: 'g-2509-default-start-and-near-quota-peace-canonical',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}

/// Stalled-futile / tribe-distraction Game builder (explicit province maps).
Game buildStalledFutileExpandPeaceGame({
  required int ownProvinces,
  Map<String, List<String>> gpRivalProvincesById = const {},
  Map<String, List<String>> minorOwProvincesByMinorId = const {},
  List<String> tribeIds = const [],
  List<String> atWarFactionIds = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
  int turnNumber = 40,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    for (final entry in gpRivalProvincesById.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
    for (final entry in minorOwProvincesByMinorId.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  return Game(
    id:
        'g-2509-stalled-futile-gp-and-tribe-distraction-canonical-'
        'own$ownProvinces',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      for (final id in gpRivalProvincesById.keys)
        Player(id: id, displayName: id, isHuman: false),
    ],
    minorNations: [
      for (final id in minorOwProvincesByMinorId.keys)
        MinorNation(id: id, displayName: id),
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

/// Default-start futile-minor Game builder (single rival GP count).
Game buildDefaultStartFutileMinorExpandPeaceGame({
  required int ownProvinces,
  int rivalGpProvinces = 0,
  Map<String, List<String>> minorOwProvincesByMinorId = const {},
  List<String> atWarMinorIds = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
  String rivalGpId = 'gp_rival',
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    if (rivalGpProvinces > 0)
      for (var i = 1; i <= rivalGpProvinces; i++)
        Province(
          id: 'oldWorld|${rivalGpId}_$i',
          regionId: 'oldWorld',
          ownerId: rivalGpId,
        ),
    for (final entry in minorOwProvincesByMinorId.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  return Game(
    id:
        'g-2509-default-start-futile-minor-canonical-'
        'own$ownProvinces-rival$rivalGpProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      if (rivalGpProvinces > 0)
        Player(id: rivalGpId, displayName: 'GP_RIVAL', isHuman: false),
    ],
    minorNations: [
      for (final id in minorOwProvincesByMinorId.keys)
        MinorNation(id: id, displayName: id),
    ],
    diplomacyRelations: [
      for (final id in atWarMinorIds)
        DiplomacyRelation(
          factionId1: ownPlayerId,
          factionId2: id,
          state: RelationState.atWar,
          score: 30,
        ),
    ],
  );
}

/// Below-quota tribe-distraction Game builder.
Game buildTribeDistractionExpandPeaceGame({
  required int ownProvinces,
  required int ownRegiments,
  Map<String, List<String>> minorOwnedInvadables = const {},
  Map<String, List<String>> tribeOwnedInvadables = const {},
  List<String> atWarMinors = const [],
  List<String> atWarTribes = const [],
  List<String> atWarRivalGps = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    for (final entry in minorOwnedInvadables.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
    for (final entry in tribeOwnedInvadables.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  final allMinorIds = <String>{...minorOwnedInvadables.keys, ...atWarMinors};

  return Game(
    id: 'g-2847-tribe-distraction-own$ownProvinces-reg$ownRegiments',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: ownRegiments > 0
          ? <Army>[
              Army(
                id: homeArmyIdFor(ownPlayerId),
                ownerId: ownPlayerId,
                regionId: 'oldWorld',
                stationedProvinceId: ownProvinces > 0
                    ? 'oldWorld|${ownPlayerId}_1'
                    : 'oldWorld|capital',
                regimentUnitIds: <String>[
                  for (var i = 1; i <= ownRegiments; i++)
                    'u_${ownPlayerId}_$i',
                ],
                isHomeArmy: true,
              ),
            ]
          : const <Army>[],
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      for (final id in atWarRivalGps)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: [
      for (final minorId in allMinorIds)
        MinorNation(id: minorId, displayName: minorId),
    ],
    tribes: [
      for (final tribeId in atWarTribes)
        Tribe(id: tribeId, displayName: tribeId),
    ],
    diplomacyRelations: [
      for (final id in [...atWarMinors, ...atWarTribes, ...atWarRivalGps])
        DiplomacyRelation(
          factionId1: ownPlayerId,
          factionId2: id,
          state: RelationState.atWar,
          score: 30,
        ),
    ],
  );
}

/// Stalled minor / GP-blocker pivot Game builder.
Game buildPivotExpandPeaceGame({
  required List<Province> provinces,
  required List<String> atWarFactionIds,
  List<MinorNation> minorNations = const [],
  Set<String> extraGpIds = const {},
  String ownPlayerId = kExpandPeaceGpOwn,
  int turnNumber = 50,
  int diplomacyScore = 10,
}) {
  final playerIds = <String>{
    ownPlayerId,
    ...extraGpIds,
    for (final id in atWarFactionIds)
      if (id.startsWith('gp')) id,
  };
  return Game(
    id: 'g-3717-pivot-${provinces.length}',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: [
      for (final id in playerIds)
        Player(id: id, displayName: id.toUpperCase(), isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: [
      for (final id in atWarFactionIds)
        DiplomacyRelation(
          factionId1: ownPlayerId,
          factionId2: id,
          state: RelationState.atWar,
          score: diplomacyScore,
        ),
    ],
  );
}

/// Survival-aggregator Game builder (critical + zero-regiment arms).
Game buildSurvivalGreatPowerPeaceGame({
  required int ownProvinces,
  required int ownRegimentCount,
  String? enemyGpId,
  int enemyOwProvinces = 0,
  int enemyRegimentCount = 0,
  String? minorId,
  List<String> atWarFactionIds = const [],
  String ownPlayerId = kExpandPeaceGpOwn,
}) {
  final provinces = <Province>[
    Province(
      id: 'oldWorld|${ownPlayerId}_home',
      regionId: 'oldWorld',
      ownerId: ownPlayerId,
    ),
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${ownPlayerId}_$i',
        regionId: 'oldWorld',
        ownerId: ownPlayerId,
      ),
    if (enemyGpId != null) ...[
      Province(
        id: 'oldWorld|${enemyGpId}_home',
        regionId: 'oldWorld',
        ownerId: enemyGpId,
      ),
      for (var i = 1; i <= enemyOwProvinces; i++)
        Province(
          id: 'oldWorld|${enemyGpId}_$i',
          regionId: 'oldWorld',
          ownerId: enemyGpId,
        ),
    ],
    if (minorId != null)
      Province(
        id: 'oldWorld|${minorId}_home',
        regionId: 'oldWorld',
        ownerId: minorId,
      ),
  ];

  final armies = <Army>[
    Army(
      id: homeArmyIdFor(ownPlayerId),
      ownerId: ownPlayerId,
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|${ownPlayerId}_home',
      regimentUnitIds: List<String>.unmodifiable(
        List<String>.generate(
          ownRegimentCount,
          (i) => 'u_${ownPlayerId}_${i + 1}',
        ),
      ),
      isHomeArmy: true,
    ),
    if (enemyGpId != null)
      Army(
        id: homeArmyIdFor(enemyGpId),
        ownerId: enemyGpId,
        regionId: 'oldWorld',
        stationedProvinceId: 'oldWorld|${enemyGpId}_home',
        regimentUnitIds: List<String>.unmodifiable(
          List<String>.generate(
            enemyRegimentCount,
            (i) => 'u_${enemyGpId}_${i + 1}',
          ),
        ),
        isHomeArmy: true,
      ),
  ];

  return Game(
    id:
        'g-2509-survival-aggregator-canonical-'
        'own${ownProvinces}_${ownRegimentCount}_'
        'enemy${enemyGpId ?? 'none'}_${enemyOwProvinces}_${enemyRegimentCount}_'
        'minor${minorId ?? 'none'}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      if (enemyGpId != null)
        Player(
          id: enemyGpId,
          displayName: enemyGpId.toUpperCase(),
          isHuman: false,
        ),
    ],
    minorNations: [
      if (minorId != null) MinorNation(id: minorId, displayName: minorId),
    ],
    tribes: const [],
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

/// `count` Old World provinces owned by [owner] for peace-matrix rows.
List<Province> oldWorldProvincesForExpandPeaceMatrix(
  String owner,
  int count, {
  int start = 0,
}) => <Province>[
  for (var i = start; i < start + count; i++)
    Province(id: 'oldWorld|${owner}_$i', regionId: 'oldWorld', ownerId: owner),
];

/// Peace-matrix Game builder (predicate + target-decider case modules).
Game buildExpandPeaceMatrixGame({
  required List<Province> owProvinces,
  required List<Player> players,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<Province> nwProvinces = const [],
  int turnNumber = 80,
  String gameId = 'g-expand-peace-predicate-matrix',
}) => Game(
  id: gameId,
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    oldWorld: RegionData(provinces: owProvinces),
    newWorld: RegionData(provinces: nwProvinces),
  ),
  players: players,
  minorNations: minorNations,
  tribes: tribes,
);

/// Peace-matrix snapshot builder shared by predicate and target rows.
AIWorldSnapshot buildExpandPeaceMatrixSnapshot({
  required String playerId,
  required List<String> atWarWith,
  required int oldWorldProvincesOwned,
  List<String> invadableProvinceIdsSorted = const [],
}) => AIWorldSnapshot(
  playerId: playerId,
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
