/// Weak-holdings invadable-blocker Game builder (Refs #2509 / #4291 Slice C).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'expand_phase_peace_test_support_core.dart';

/// Default blocker GP id for weak-holdings peace pins.
const String kWeakHoldingsGpBlocker = 'gp_blocker';

/// Default minor id for weak-holdings peace pins.
const String kWeakHoldingsMinor1 = 'minor1';

/// Builds a `Game` for `weakHoldingsInvadableBlockerPeaceTargets` pins.
Game buildWeakHoldingsInvadableBlockerGame({
  required int ownProvinces,
  required int blockerOwnProvinces,
  Map<String, List<String>> extraInvadableOwners = const <String, List<String>>{},
  List<String> atWarFactionIds = const <String>[kWeakHoldingsGpBlocker],
  List<MinorNation> minorNations = const <MinorNation>[
    MinorNation(id: kWeakHoldingsMinor1, displayName: 'M1'),
  ],
  String ownPlayerId = kExpandPeaceGpOwn,
  String blockerPlayerId = kWeakHoldingsGpBlocker,
}) {
  return Game(
    id:
        'g-2509-weak-holdings-canonical-'
        'own$ownProvinces-blocker$blockerOwnProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 1; i <= ownProvinces; i++)
            Province(
              id: 'oldWorld|${ownPlayerId}_$i',
              regionId: 'oldWorld',
              ownerId: ownPlayerId,
            ),
          for (var i = 1; i <= blockerOwnProvinces; i++)
            Province(
              id: 'oldWorld|${blockerPlayerId}_$i',
              regionId: 'oldWorld',
              ownerId: blockerPlayerId,
            ),
          for (final entry in extraInvadableOwners.entries)
            for (final pid in entry.value)
              Province(id: pid, regionId: 'oldWorld', ownerId: entry.key),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: <Player>[
      Player(id: ownPlayerId, displayName: 'GP_OWN', isHuman: false),
      Player(id: blockerPlayerId, displayName: 'GP_BLOCKER', isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: <DiplomacyRelation>[
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
