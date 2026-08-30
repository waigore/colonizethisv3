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

