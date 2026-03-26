import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';

/// Ship build cost configuration. SPEC/game/ships-and-naval.md § Ship build economy.
class ShipEconomyEntry {
  const ShipEconomyEntry({
    required this.shipTypeId,
    required this.buildTreasuryCost,
    this.buildInputs = const {},
  });

  final String shipTypeId;
  final int buildTreasuryCost;
  final Map<CommodityId, int> buildInputs;
}

/// Ship economy catalog. SPEC/game/ships-and-naval.md (canonical table).
class ShipEconomyCatalog {
  ShipEconomyCatalog._();

  static final ShipEconomyEntry carrack = ShipEconomyEntry(
    shipTypeId: 'carrack',
    buildTreasuryCost: 8000,
    buildInputs: {CommodityCatalog.lumber.id: 2, CommodityCatalog.fabric.id: 1},
  );

  static final ShipEconomyEntry fluyte = ShipEconomyEntry(
    shipTypeId: 'fluyte',
    buildTreasuryCost: 6000,
    buildInputs: {CommodityCatalog.lumber.id: 1, CommodityCatalog.fabric.id: 1},
  );

  static final ShipEconomyEntry sloop = ShipEconomyEntry(
    shipTypeId: 'sloop',
    buildTreasuryCost: 5500,
    buildInputs: {CommodityCatalog.lumber.id: 1, CommodityCatalog.fabric.id: 1},
  );

  static final ShipEconomyEntry trader = ShipEconomyEntry(
    shipTypeId: 'trader',
    buildTreasuryCost: 7500,
    buildInputs: {CommodityCatalog.lumber.id: 2, CommodityCatalog.fabric.id: 2},
  );

  static final ShipEconomyEntry galleon = ShipEconomyEntry(
    shipTypeId: 'galleon',
    buildTreasuryCost: 9500,
    buildInputs: {CommodityCatalog.lumber.id: 3, CommodityCatalog.fabric.id: 2},
  );

  static final ShipEconomyEntry indiaman = ShipEconomyEntry(
    shipTypeId: 'indiaman',
    buildTreasuryCost: 11000,
    buildInputs: {CommodityCatalog.lumber.id: 3, CommodityCatalog.fabric.id: 3},
  );

  static final ShipEconomyEntry frigate = ShipEconomyEntry(
    shipTypeId: 'frigate',
    buildTreasuryCost: 10500,
    buildInputs: {CommodityCatalog.lumber.id: 2, CommodityCatalog.fabric.id: 2},
  );

  static final ShipEconomyEntry raider = ShipEconomyEntry(
    shipTypeId: 'raider',
    buildTreasuryCost: 11500,
    buildInputs: {
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.fabric.id: 1,
      CommodityCatalog.castIron.id: 2,
    },
  );

  static final ShipEconomyEntry shipOfTheLine = ShipEconomyEntry(
    shipTypeId: 'ship_of_the_line',
    buildTreasuryCost: 16500,
    buildInputs: {CommodityCatalog.lumber.id: 5, CommodityCatalog.fabric.id: 3},
  );

  static final ShipEconomyEntry clipper = ShipEconomyEntry(
    shipTypeId: 'clipper',
    buildTreasuryCost: 13500,
    buildInputs: {CommodityCatalog.lumber.id: 3, CommodityCatalog.fabric.id: 3},
  );

  static final ShipEconomyEntry merchantSteamship = ShipEconomyEntry(
    shipTypeId: 'merchant_steamship',
    buildTreasuryCost: 15500,
    buildInputs: {
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.fabric.id: 2,
      CommodityCatalog.coal.id: 3,
    },
  );

  static final ShipEconomyEntry ironclad = ShipEconomyEntry(
    shipTypeId: 'ironclad',
    buildTreasuryCost: 21000,
    buildInputs: {
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.fabric.id: 2,
      CommodityCatalog.castIron.id: 5,
    },
  );

  static final List<ShipEconomyEntry> all = [
    carrack,
    fluyte,
    sloop,
    trader,
    galleon,
    indiaman,
    frigate,
    raider,
    shipOfTheLine,
    clipper,
    merchantSteamship,
    ironclad,
  ];

  static final Map<String, ShipEconomyEntry> byId = {
    for (final e in all) e.shipTypeId: e,
  };
}

/// True if [unitType] is a ship type (buildable as naval unit, spawns in home fleet).
bool isShipUnitType(String unitType) =>
    ShipEconomyCatalog.byId.containsKey(unitType);
