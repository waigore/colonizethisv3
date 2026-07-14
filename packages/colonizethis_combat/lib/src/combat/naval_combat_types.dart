// Naval battle types, ship-list clone helper, and retreat constants.
// SPEC/program/naval-combat-resolution.md; SPEC/game/ships-and-naval.md.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Canonical clone of a naval ship-instance list (Refs #3448, AC5).
///
/// Centralizes the defensive copy that previously used raw `List.from(...)` at
/// several naval resolution sites (battle-context snapshots and per-round
/// working lists). Returns a growable list so callers that mutate the copy
/// (for example `removeAt` during casualty application) keep working. Routing
/// every ship-list clone through this one helper lets
/// `repo.combat_no_raw_copies_in_resolution` forbid re-introducing raw
/// `List.from` clones on ship collections in the resolution path.
List<ShipInstance> copyNavalShips(List<ShipInstance> ships) => <ShipInstance>[
  ...ships,
];

/// Retreat base chance. SPEC/game/ships-and-naval.md.
const double kNavalRetreatBaseChance = 0.6;

/// Retreat speed advantage factor per MV point difference.
const double kNavalRetreatSpeedFactor = 0.1;

/// Enemy aggression when enemy is on Patrol.
const double kNavalRetreatEnemyPatrol = 0.1;

/// Enemy aggression when enemy is on Blockade.
const double kNavalRetreatEnemyBlockade = 0.2;

/// One side in a sea battle: owner, ship instances, mission (used for retreat `enemyAggression` from opponent mission).
class NavalBattleSide {
  const NavalBattleSide({
    required this.ownerId,
    required this.ships,
    this.mission = FleetMission.none,
  });

  final String ownerId;
  final List<ShipInstance> ships;
  final FleetMission mission;

  /// Type id per ship (combat aggregation).
  List<String> get shipTypeIds => ships.map((s) => s.typeId).toList();
}

/// Sea battle context for one zone. SPEC/program/naval-combat-resolution.md.
///
/// After [normalizeNavalBattleSidesForAttacker], [side1] is the **attacker** and [side2] is the **defender**.
class BattleContextSea {
  const BattleContextSea({
    required this.seaZoneId,
    required this.side1,
    required this.side2,
  });

  final String seaZoneId;
  final NavalBattleSide side1;
  final NavalBattleSide side2;
}

enum NavalBattleOutcome {
  side1Victory,
  side2Victory,
  stalemate,
  mutualDestruction,
}

/// Result of resolving one sea battle: updated fleet lists (sunk ships removed).
class NavalBattleResult {
  const NavalBattleResult({
    required this.survivingShipsSide1,
    required this.survivingShipsSide2,
    this.side1Retreated = false,
    this.side2Retreated = false,
    this.outcome = NavalBattleOutcome.stalemate,
  });

  final List<ShipInstance> survivingShipsSide1;
  final List<ShipInstance> survivingShipsSide2;
  final bool side1Retreated;
  final bool side2Retreated;
  final NavalBattleOutcome outcome;
}
