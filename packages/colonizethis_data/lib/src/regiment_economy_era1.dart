import 'commodities.dart';
import 'regiment_economy_model.dart';

/// Era 1 regiment economy entries. SPEC/game/military-units.md.
class RegimentEconomyEra1 {
  RegimentEconomyEra1._();

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

  static final List<RegimentEconomy> all = [
    peasantLevies,
    pikemen,
    arquebusiers,
    bowmen,
    squires,
    knights,
    culverin,
  ];
}
