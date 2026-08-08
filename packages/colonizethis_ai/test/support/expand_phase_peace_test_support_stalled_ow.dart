/// Stalled OW expansion / GP-blocker Game builders (Refs #2509 / #4291 Slice C).
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'expand_phase_peace_test_support_core.dart';

/// Minor id used by stalled-OW zero-regiment peace-pass pins.
const String kStalledOwMinorZeta = 'minor_zeta';

/// Pristine stalled-OW Game with no at-war factions (peace-pass negative control).
Game buildStalledOwPristineGame() {
  return Game(
    id: 'g-2509-needs-peace-pass-pristine',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 1; i <= 6; i++)
            Province(
              id: 'oldWorld|${kExpandPeaceGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: kExpandPeaceGpOwn,
            ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const <Army>[],
    ),
    players: const <Player>[
      Player(id: kExpandPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
    ],
    minorNations: const <MinorNation>[],
    tribes: const <Tribe>[],
    diplomacyRelations: const <DiplomacyRelation>[],
  );
}

/// Zero-regiment at-war minor Game that triggers stalled peace-pass deciders.
Game buildStalledOwZeroRegimentAtWarGame() {
  return Game(
    id: 'g-2509-needs-peace-pass-zero-reg',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 1; i <= 6; i++)
            Province(
              id: 'oldWorld|${kExpandPeaceGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: kExpandPeaceGpOwn,
            ),
          Province(
            id: 'oldWorld|${kStalledOwMinorZeta}_1',
            regionId: 'oldWorld',
            ownerId: kStalledOwMinorZeta,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: <Army>[
        Army(
          id: homeArmyIdFor(kExpandPeaceGpOwn),
          ownerId: kExpandPeaceGpOwn,
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|${kExpandPeaceGpOwn}_1',
          regimentUnitIds: const <String>[],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const <Player>[
      Player(id: kExpandPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: kStalledOwMinorZeta, displayName: 'minor_zeta'),
    ],
    tribes: const <Tribe>[],
    diplomacyRelations: const <DiplomacyRelation>[
      DiplomacyRelation(
        factionId1: kExpandPeaceGpOwn,
        factionId2: kStalledOwMinorZeta,
        state: RelationState.atWar,
        score: 30,
      ),
    ],
  );
}

/// GP-only invadable frontier for stalled OW GP-blocker focus pins.
Game buildStalledOwGpOnlyInvadableGame({required int ownOwProvinces}) {
  return Game(
    id: 'g-stalled-blocker-gp-only',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 0; i < ownOwProvinces; i++)
            Province(
              id: 'oldWorld|gp5_$i',
              regionId: 'oldWorld',
              ownerId: 'gp5',
            ),
          const Province(
            id: 'oldWorld|gp6_frontier',
            regionId: 'oldWorld',
            ownerId: 'gp6',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const <Player>[
      Player(id: 'gp5', displayName: 'P5', isHuman: false),
      Player(id: 'gp6', displayName: 'P6', isHuman: false),
    ],
  );
}

/// Minor + GP invadable frontier for stalled OW GP-blocker pivot pins.
Game buildStalledOwMinorAndGpInvadableGame({required int ownOwProvinces}) {
  return Game(
    id: 'g-stalled-blocker-minor-pivot',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 0; i < ownOwProvinces; i++)
            Province(
              id: 'oldWorld|gp5_$i',
              regionId: 'oldWorld',
              ownerId: 'gp5',
            ),
          const Province(
            id: 'oldWorld|gp6_frontier',
            regionId: 'oldWorld',
            ownerId: 'gp6',
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: 'minor1',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const <Player>[
      Player(id: 'gp5', displayName: 'P5', isHuman: false),
      Player(id: 'gp6', displayName: 'P6', isHuman: false),
    ],
    minorNations: const <MinorNation>[
      MinorNation(id: 'minor1', displayName: 'M1'),
    ],
  );
}

/// Tribe-only invadable frontier for stalled OW GP-blocker focus pins.
Game buildStalledOwTribeOnlyInvadableGame({required int ownOwProvinces}) {
  return Game(
    id: 'g-stalled-blocker-tribe-only',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
      oldWorld: RegionData(
        provinces: <Province>[
          for (var i = 0; i < ownOwProvinces; i++)
            Province(
              id: 'oldWorld|gp5_$i',
              regionId: 'oldWorld',
              ownerId: 'gp5',
            ),
          const Province(
            id: 'oldWorld|tribe1_p1',
            regionId: 'oldWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const <Player>[
      Player(id: 'gp5', displayName: 'P5', isHuman: false),
    ],
    tribes: const <Tribe>[Tribe(id: 'tribe1', displayName: 'T1')],
  );
}
