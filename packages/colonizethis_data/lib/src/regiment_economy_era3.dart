import 'commodities.dart';
import 'regiment_economy_model.dart';

/// Era 3 regiment economy entries. SPEC/game/military-units.md.
class RegimentEconomyEra3 {
  RegimentEconomyEra3._();

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

  static final List<RegimentEconomy> all = [
    skirmishers,
    regulars,
    grenadiers,
    hussars,
    cuirassiers,
    lightArtillery,
    heavyArtillery,
  ];
}
