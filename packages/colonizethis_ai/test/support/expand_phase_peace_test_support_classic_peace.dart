/// Classic peace-pin Game builders (critical / distraction / zero-regiment / peer).
library;

import 'expand_phase_peace_test_support_core.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

