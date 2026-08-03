// Shared fixtures for expand_phase_planner_gp_blocker_focus_peace pins (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
const String gpBlockerFocusGpOwn = 'gp4';
const String gpBlockerFocusGpBlocker = 'gp3';
const String gpBlockerFocusGpDistraction = 'gp5';
const String gpBlockerFocusMinor1 = 'minor1';

Game gpBlockerFocusGpBlockerFocusGame({
  required List<Province> provinces,
  required List<String> atWarFactionIds,
  List<MinorNation> minorNations = const [],
  Set<String> extraGpIds = const {},
}) {
  final playerIds = <String>{
    gpBlockerFocusGpOwn,
    ...extraGpIds,
    for (final id in atWarFactionIds)
      if (id.startsWith('gp')) id,
  };
  return Game(
    id: 'g-2509-gp-blocker-focus-${provinces.length}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
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
          factionId1: gpBlockerFocusGpOwn,
          factionId2: id,
          state: RelationState.atWar,
          score: 10,
        ),
    ],
  );
}
