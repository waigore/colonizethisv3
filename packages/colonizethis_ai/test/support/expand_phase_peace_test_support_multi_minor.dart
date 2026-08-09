/// Multi-minor distraction peace Game builder (Refs #2509 / #4291 Slice C).
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'expand_phase_peace_test_support_core.dart';

/// Builds a minimal `Game` for `belowQuotaMultiMinorDistractionPeaceTargets` pins.
Game buildExpandPeaceMultiMinorGame({
  required int ownProvinces,
  required int ownRegiments,
  Map<String, List<String>> minorOwnedInvadables = const <String, List<String>>{},
  List<String> atWarMinors = const <String>[],
  List<String> atWarTribes = const <String>[],
  List<String> atWarRivalGps = const <String>[],
  List<String> peacefulMinors = const <String>[],
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
  ];

  final players = <Player>[
    Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
    for (final id in atWarRivalGps)
      Player(id: id, displayName: id.toUpperCase(), isHuman: false),
  ];

  final allMinorIds = <String>{
    ...minorOwnedInvadables.keys,
    ...atWarMinors,
    ...peacefulMinors,
  };
  final minorNations = <MinorNation>[
    for (final minorId in allMinorIds)
      MinorNation(id: minorId, displayName: minorId),
  ];

  final tribes = <Tribe>[
    for (final tribeId in atWarTribes) Tribe(id: tribeId, displayName: tribeId),
  ];

  final relations = <DiplomacyRelation>[
    for (final id in atWarMinors)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final id in atWarTribes)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final id in atWarRivalGps)
      DiplomacyRelation(
        factionId1: ownPlayerId,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  final armies = <Army>[
    if (ownRegiments > 0)
      Army(
        id: homeArmyIdFor(ownPlayerId),
        ownerId: ownPlayerId,
        regionId: 'oldWorld',
        stationedProvinceId: ownProvinces > 0
            ? 'oldWorld|${ownPlayerId}_1'
            : 'oldWorld|capital',
        regimentUnitIds: <String>[
          for (var i = 1; i <= ownRegiments; i++) 'u_${ownPlayerId}_$i',
        ],
        isHomeArmy: true,
      ),
  ];

  return Game(
    id:
        'g-2509-multi-minor-distraction-'
        'own$ownProvinces-reg$ownRegiments-'
        '${minorOwnedInvadables.keys.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      armies: armies,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}
