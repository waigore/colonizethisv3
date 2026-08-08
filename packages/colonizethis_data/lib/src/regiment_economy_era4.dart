import 'commodities.dart';
import 'regiment_economy_model.dart';

/// Era 4 regiment economy entries. SPEC/game/military-units.md.
class RegimentEconomyEra4 {
  RegimentEconomyEra4._();

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

  static final List<RegimentEconomy> all = [
    sharpshooters,
    rifleInfantry,
    guards,
    scouts,
    carbineCavalry,
    fieldArtillery,
    siegeGuns,
  ];
}
