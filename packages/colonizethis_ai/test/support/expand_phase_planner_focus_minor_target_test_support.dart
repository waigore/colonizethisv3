// Shared Game fixtures for expand_phase_planner_focus_minor_target pins
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

const String kFocusMinorGpOwn = 'gp_own';
const String kFocusMinorGpRival = 'gp_rival';
const String kFocusMinorMinorAlpha = 'minor_alpha';
const String kFocusMinorMinorBeta = 'minor_beta';
const String kFocusMinorMinorGamma = 'minor_gamma';
const String kFocusMinorTribeOne = 'tribe_one';

/// Builds a minimal `Game` where:
///   * `gp_own` holds [ownProvinces] OW provinces (so quota-band
///     ownership counts via `Game.worldState.oldWorld.provinces` are
///     deterministic without forcing the test to enumerate them).
///   * Each entry in [minorOwnedInvadables] places that minor as the
///     owner of every province id in the value list (these are the
///     ids the snapshot exposes via `invadableProvinceIdsSorted`).
///   * Every minor in [atWarMinors] is in `RelationState.atWar`
///     against `gp_own`. Minors not listed here exist on the map but
///     are at peace.
///   * Every tribe in [atWarTribes] is in `RelationState.atWar`. The
///     focused-minor scan iterates `Game.minorNations` only, so
///     tribes here exercise the "tribes don't participate" rule.
///   * Every GP in [atWarRivalGps] is in `RelationState.atWar`. The
///     focused-minor scan never inspects GPs (the same iteration
///     filter); the GP at-war set keeps the fixture honest about
///     `threats.atWarWith` mixing in non-minor entries.
Game expandPhasePlannerFocusMinorTargetGame({
  required int ownProvinces,
  Map<String, List<String>> minorOwnedInvadables = const {},
  List<String> atWarMinors = const [],
  List<String> atWarTribes = const [],
  List<String> atWarRivalGps = const [],
  List<String> peacefulMinors = const [],
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|${kFocusMinorGpOwn}_$i',
        regionId: 'oldWorld',
        ownerId: kFocusMinorGpOwn,
      ),
    for (final entry in minorOwnedInvadables.entries)
      for (final pid in entry.value)
        Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
  ];

  final players = <Player>[
    const Player(id: kFocusMinorGpOwn, displayName: 'GP_OWN', isHuman: false),
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
    for (final tribeId in atWarTribes)
      Tribe(id: tribeId, displayName: tribeId),
  ];

  final relations = <DiplomacyRelation>[
    for (final id in atWarMinors)
      DiplomacyRelation(
        factionId1: kFocusMinorGpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final id in atWarTribes)
      DiplomacyRelation(
        factionId1: kFocusMinorGpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
    for (final id in atWarRivalGps)
      DiplomacyRelation(
        factionId1: kFocusMinorGpOwn,
        factionId2: id,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id:
        'g-2509-focus-minor-canonical-'
        'own$ownProvinces-${minorOwnedInvadables.keys.join("-")}',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: relations,
  );
}
