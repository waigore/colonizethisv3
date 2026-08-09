import 'commodities.dart';
import 'regiment_economy_model.dart';

/// Era 2 regiment economy entries. SPEC/game/military-units.md.
class RegimentEconomyEra2 {
  RegimentEconomyEra2._();

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

  static final List<RegimentEconomy> all = [
    calivermen,
    halberdiers,
    musketeers,
    cossacks,
    lancers,
    harquebusiers,
    horseArtillery,
    royalArtillery,
  ];
}
