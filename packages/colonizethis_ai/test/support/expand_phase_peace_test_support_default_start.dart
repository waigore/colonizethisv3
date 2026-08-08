/// Default-start / near-quota / stalled-futile / futile-minor peace builders.
library;

import 'expand_phase_peace_test_support_core.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

