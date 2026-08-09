/// Tribe-distraction / pivot / survival-aggregator peace builders.
library;

import 'expand_phase_peace_test_support_core.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

