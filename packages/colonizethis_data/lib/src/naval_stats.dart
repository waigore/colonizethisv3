// Per-ship naval combat and interception stats. SPEC/program/naval-combat-resolution.md, naval-movement-resolution.md.

/// Naval stats for one ship type (FRP, RNG, ARM, HULL, MV, interceptRating, fleeRating, cargoHold).
class NavalStatsEntry {
  const NavalStatsEntry({
    this.firepower = 1,
    this.range = 1,
    this.armour = 1,
    this.hull = 1,
    this.movement = 1,
    this.interceptRating = 1,
    this.fleeRating = 1,
    this.cargoHold = 0,
  });

  final int firepower;
  final int range;
  final int armour;
  final int hull;
  final int movement;
  final int interceptRating;
  final int fleeRating;
  /// Cargo capacity in holds for this ship type. Each hold = 1 unit per turn.
  final int cargoHold;
}

/// Naval stats per ship type id. Used by naval combat and interception.
class NavalStatsCatalog {
  NavalStatsCatalog._();

  static const NavalStatsEntry carrack = NavalStatsEntry(
    firepower: 2,
    range: 1,
    armour: 1,
    hull: 2,
    movement: 2,
    interceptRating: 1,
    fleeRating: 2,
    cargoHold: 3,
  );

  static const NavalStatsEntry fluyte = NavalStatsEntry(
    firepower: 1,
    range: 1,
    armour: 1,
    hull: 1,
    movement: 2,
    interceptRating: 1,
    fleeRating: 3,
    cargoHold: 4,
  );

  static const Map<String, NavalStatsEntry> byId = {
    'carrack': carrack,
    'fluyte': fluyte,
  };

  static NavalStatsEntry get(String shipTypeId) =>
      byId[shipTypeId] ?? const NavalStatsEntry();
}
