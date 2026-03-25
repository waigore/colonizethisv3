// Per-ship naval combat and interception stats. SPEC/game/ships-and-naval.md § Ship combat and cargo stats;
// resolution: SPEC/program/naval-combat-resolution.md, naval-movement-resolution.md.

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

  static const NavalStatsEntry sloop = NavalStatsEntry(
    firepower: 2,
    range: 2,
    armour: 1,
    hull: 2,
    movement: 3,
    interceptRating: 4,
    fleeRating: 4,
    cargoHold: 0,
  );

  static const NavalStatsEntry trader = NavalStatsEntry(
    firepower: 1,
    range: 1,
    armour: 1,
    hull: 2,
    movement: 2,
    interceptRating: 1,
    fleeRating: 3,
    cargoHold: 5,
  );

  static const NavalStatsEntry galleon = NavalStatsEntry(
    firepower: 2,
    range: 1,
    armour: 2,
    hull: 4,
    movement: 2,
    interceptRating: 1,
    fleeRating: 2,
    cargoHold: 6,
  );

  static const NavalStatsEntry indiaman = NavalStatsEntry(
    firepower: 2,
    range: 2,
    armour: 2,
    hull: 5,
    movement: 2,
    interceptRating: 1,
    fleeRating: 2,
    cargoHold: 8,
  );

  static const NavalStatsEntry frigate = NavalStatsEntry(
    firepower: 4,
    range: 3,
    armour: 2,
    hull: 4,
    movement: 3,
    interceptRating: 5,
    fleeRating: 4,
    cargoHold: 0,
  );

  static const NavalStatsEntry raider = NavalStatsEntry(
    firepower: 3,
    range: 2,
    armour: 2,
    hull: 3,
    movement: 4,
    interceptRating: 6,
    fleeRating: 5,
    cargoHold: 0,
  );

  static const NavalStatsEntry shipOfTheLine = NavalStatsEntry(
    firepower: 6,
    range: 4,
    armour: 4,
    hull: 8,
    movement: 2,
    interceptRating: 2,
    fleeRating: 1,
    cargoHold: 0,
  );

  static const NavalStatsEntry clipper = NavalStatsEntry(
    firepower: 1,
    range: 2,
    armour: 1,
    hull: 3,
    movement: 4,
    interceptRating: 2,
    fleeRating: 4,
    cargoHold: 7,
  );

  static const NavalStatsEntry merchantSteamship = NavalStatsEntry(
    firepower: 2,
    range: 2,
    armour: 3,
    hull: 5,
    movement: 3,
    interceptRating: 1,
    fleeRating: 3,
    cargoHold: 9,
  );

  static const NavalStatsEntry ironclad = NavalStatsEntry(
    firepower: 5,
    range: 3,
    armour: 8,
    hull: 6,
    movement: 3,
    interceptRating: 2,
    fleeRating: 2,
    cargoHold: 0,
  );

  static const Map<String, NavalStatsEntry> byId = {
    'carrack': carrack,
    'fluyte': fluyte,
    'sloop': sloop,
    'trader': trader,
    'galleon': galleon,
    'indiaman': indiaman,
    'frigate': frigate,
    'raider': raider,
    'ship_of_the_line': shipOfTheLine,
    'clipper': clipper,
    'merchant_steamship': merchantSteamship,
    'ironclad': ironclad,
  };

  static NavalStatsEntry get(String shipTypeId) =>
      byId[shipTypeId] ?? const NavalStatsEntry();
}
