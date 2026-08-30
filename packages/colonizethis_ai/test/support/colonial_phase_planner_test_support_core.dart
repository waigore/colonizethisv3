/// Core COLONIAL phase-planner fixtures: ids, rosters, game/snapshot builders
/// (Refs #3967 / #3972). Dispatch scaffolds live in
/// `colonial_phase_planner_test_support_dispatch.dart`.
library;

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
export 'colonial_phase_planner_test_support_games.dart';

/// OW province id used by phase-planner dispatch COLONIAL / lite scaffolds.
const String kColonialPhaseDispatchOwProvGp1 = 'oldWorld|gp1_a';

/// Invadable OW minor province for dispatch EXPAND / COLONIAL-lite scaffolds.
const String kColonialPhaseDispatchOwProvMinor = 'oldWorld|m1_a';

/// Default active GP id used by most COLONIAL military / naval pins.
const String kColonialPhaseGp1 = 'gp1';

/// Peer GP id for multi-player isolation pins.
const String kColonialPhaseGp2 = 'gp2';

/// Third GP id for multi-owner / isolation pins.
const String kColonialPhaseGp3 = 'gp3';

/// Fourth GP id for COLONIAL peace multi-peer pins.
const String kColonialPhaseGp4 = 'gp4';

/// Default tribe id for NW invasion-target pins.
const String kColonialPhaseTribe1 = 'tribe1';

/// Second tribe id for multi-tribe at-war pins.
const String kColonialPhaseTribe2 = 'tribe2';

/// Third tribe id for COLONIAL-lite overture union pins.
const String kColonialPhaseTribe3 = 'tribe3';

/// Default minor-nation id for mixed-owner pins.
const String kColonialPhaseMinor1 = 'minor1';

/// Canonical NW province id used by Path E lock-recovery waiver pins.
const String kColonialPhaseNwProvTribeA = 'newWorld|tribe1_a';

/// Minimum at-quota OW province count per GP for COLONIAL peace pins.
///
/// Matches `kObserverConquestMinOwProvincesPerGp = 10`.
const int kColonialPeaceOwProvincesAtQuota = 10;

/// Expand-economy override that arms NW treasury-recovery Path E.
const ExpandEconomyPlan kNwTreasuryRecoveryOverridePlan = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

/// Default three-GP roster with high treasury for destination-filter pins.
const List<Player> kColonialPhaseDefaultPlayers = <Player>[
  Player(
    id: kColonialPhaseGp1,
    displayName: 'GP1',
    isHuman: false,
    treasury: 9999,
  ),
  Player(
    id: kColonialPhaseGp2,
    displayName: 'GP2',
    isHuman: false,
    treasury: 9999,
  ),
  Player(
    id: kColonialPhaseGp3,
    displayName: 'GP3',
    isHuman: false,
    treasury: 9999,
  ),
];

/// Three-GP roster without treasury overrides (COLONIAL-lite naval pins).
const List<Player> kColonialLiteNavalDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
  Player(id: kColonialPhaseGp3, displayName: 'GP3', isHuman: false),
];

/// Two-GP roster for COLONIAL-lite overture pins.
const List<Player> kColonialLiteOvertureDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
];

/// Two-GP roster for COLONIAL civilian pins.
const List<Player> kColonialCivilianDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
];

/// Four-GP roster for COLONIAL peace pins.
const List<Player> kColonialPeaceDefaultPlayers = <Player>[
  Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
  Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
  Player(id: kColonialPhaseGp3, displayName: 'GP3', isHuman: false),
  Player(id: kColonialPhaseGp4, displayName: 'GP4', isHuman: false),
];
