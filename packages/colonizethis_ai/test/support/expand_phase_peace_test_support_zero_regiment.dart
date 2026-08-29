/// Zero-regiment survival Game builder for EXPAND peace pins.
library;

import 'expand_phase_peace_test_support_core.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
