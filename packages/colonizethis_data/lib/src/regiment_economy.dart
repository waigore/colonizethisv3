import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';

/// Regiment training and upkeep configuration.
/// Training cost and food upkeep: SPEC/game/military-generals.md § Regiment Economy.
/// Era/category progression aligns with tactical stats in SPEC/game/military-units.md.
/// Worker consumed at build time is enforced in order application (orders.md BuildUnitOrder,
/// development-resolution), not in this catalog.
/// SPEC/program/orders.md, SPEC/program/economy-models.md.
class RegimentEconomy {
  const RegimentEconomy({
    required this.id,
    required this.buildTreasuryCost,
    required this.buildInputs,
    required this.foodUpkeep,
  });

  /// Regiment id, matching RegimentStats.id from combat_config.dart.
  final String id;

  /// Cash cost to train one regiment of this type.
  final int buildTreasuryCost;

  /// Material inputs consumed when training the regiment.
  /// Keys are commodity ids (e.g. fabric, castIron, lumber, steel, bronze).
  final Map<CommodityId, int> buildInputs;

  /// Food units per regiment per turn consumed during the Consumption phase.
  final int foodUpkeep;
}

class RegimentEconomyCatalog {
  // Era 1
  static final RegimentEconomy peasantLevies = RegimentEconomy(
    id: 'peasant_levies',
    buildTreasuryCost: 2000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
    },
    foodUpkeep: 1,
  );

  static final RegimentEconomy pikemen = RegimentEconomy(
    id: 'pikemen',
    buildTreasuryCost: 4000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 1,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy arquebusiers = RegimentEconomy(
    id: 'arquebusiers',
    buildTreasuryCost: 5000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 1,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy bowmen = RegimentEconomy(
    id: 'bowmen',
    buildTreasuryCost: 3000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
    },
    foodUpkeep: 1,
  );

  static final RegimentEconomy squires = RegimentEconomy(
    id: 'squires',
    buildTreasuryCost: 6000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 1,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy knights = RegimentEconomy(
    id: 'knights',
    buildTreasuryCost: 8000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy culverin = RegimentEconomy(
    id: 'culverin',
    buildTreasuryCost: 8000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.lumber.id: 1,
    },
    foodUpkeep: 2,
  );

  // Era 2
  static final RegimentEconomy calivermen = RegimentEconomy(
    id: 'calivermen',
    buildTreasuryCost: 7000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 1,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy halberdiers = RegimentEconomy(
    id: 'halberdiers',
    buildTreasuryCost: 7000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy musketeers = RegimentEconomy(
    id: 'musketeers',
    buildTreasuryCost: 8000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy cossacks = RegimentEconomy(
    id: 'cossacks',
    buildTreasuryCost: 9000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy lancers = RegimentEconomy(
    id: 'lancers',
    buildTreasuryCost: 10000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy harquebusiers = RegimentEconomy(
    id: 'harquebusiers',
    buildTreasuryCost: 11000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy horseArtillery = RegimentEconomy(
    id: 'horse_artillery',
    buildTreasuryCost: 11000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy royalArtillery = RegimentEconomy(
    id: 'royal_artillery',
    buildTreasuryCost: 12000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.lumber.id: 1,
    },
    foodUpkeep: 3,
  );

  // Era 3
  static final RegimentEconomy skirmishers = RegimentEconomy(
    id: 'skirmishers',
    buildTreasuryCost: 9000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy regulars = RegimentEconomy(
    id: 'regulars',
    buildTreasuryCost: 11000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy grenadiers = RegimentEconomy(
    id: 'grenadiers',
    buildTreasuryCost: 13000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy hussars = RegimentEconomy(
    id: 'hussars',
    buildTreasuryCost: 13000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy cuirassiers = RegimentEconomy(
    id: 'cuirassiers',
    buildTreasuryCost: 15000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy lightArtillery = RegimentEconomy(
    id: 'light_artillery',
    buildTreasuryCost: 14000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.lumber.id: 1,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy heavyArtillery = RegimentEconomy(
    id: 'heavy_artillery',
    buildTreasuryCost: 16000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.lumber.id: 1,
    },
    foodUpkeep: 3,
  );

  // Era 4
  static final RegimentEconomy sharpshooters = RegimentEconomy(
    id: 'sharpshooters',
    buildTreasuryCost: 12000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy rifleInfantry = RegimentEconomy(
    id: 'rifle_infantry',
    buildTreasuryCost: 14000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
    },
    foodUpkeep: 2,
  );

  static final RegimentEconomy guards = RegimentEconomy(
    id: 'guards',
    buildTreasuryCost: 18000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.steel.id: 1,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy scouts = RegimentEconomy(
    id: 'scouts',
    buildTreasuryCost: 15000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy carbineCavalry = RegimentEconomy(
    id: 'carbine_cavalry',
    buildTreasuryCost: 18000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.horses.id: 2,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy fieldArtillery = RegimentEconomy(
    id: 'field_artillery',
    buildTreasuryCost: 18000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.steel.id: 1,
    },
    foodUpkeep: 3,
  );

  static final RegimentEconomy siegeGuns = RegimentEconomy(
    id: 'siege_guns',
    buildTreasuryCost: 22000,
    buildInputs: {
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 3,
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.steel.id: 1,
      CommodityCatalog.bronze.id: 1,
    },
    foodUpkeep: 3,
  );

  /// All regiment economy entries, one per regiment type.
  static final List<RegimentEconomy> all = [
    peasantLevies,
    pikemen,
    arquebusiers,
    bowmen,
    squires,
    knights,
    culverin,
    calivermen,
    halberdiers,
    musketeers,
    cossacks,
    lancers,
    harquebusiers,
    horseArtillery,
    royalArtillery,
    skirmishers,
    regulars,
    grenadiers,
    hussars,
    cuirassiers,
    lightArtillery,
    heavyArtillery,
    sharpshooters,
    rifleInfantry,
    guards,
    scouts,
    carbineCavalry,
    fieldArtillery,
    siegeGuns,
  ];

  /// Fast lookup by regiment id.
  static final Map<String, RegimentEconomy> byId = {
    for (final e in all) e.id: e,
  };
}

/// Minimum [RegimentEconomy.buildTreasuryCost] across the catalog.
///
/// Shared by AI planners and world-market lock-recovery (Refs #2924).
/// Linear in catalog size; cached callers should memoize if hot.
int cheapestRegimentBuildTreasuryCost() {
  var min = 999999999;
  for (final econ in RegimentEconomyCatalog.byId.values) {
    if (econ.buildTreasuryCost < min) {
      min = econ.buildTreasuryCost;
    }
  }
  return min;
}
