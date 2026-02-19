import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';

/// Ship build cost configuration. SPEC/game/ships-and-naval.md.
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

/// Ship economy catalog for Phase 5. SPEC/program/naval-movement-resolution.md.
class ShipEconomyCatalog {
  ShipEconomyCatalog._();

  static final ShipEconomyEntry carrack = ShipEconomyEntry(
    shipTypeId: 'carrack',
    buildTreasuryCost: 80,
    buildInputs: {
      CommodityCatalog.lumber.id: 2,
      CommodityCatalog.fabric.id: 1,
    },
  );

  static final ShipEconomyEntry fluyte = ShipEconomyEntry(
    shipTypeId: 'fluyte',
    buildTreasuryCost: 60,
    buildInputs: {
      CommodityCatalog.lumber.id: 1,
      CommodityCatalog.fabric.id: 1,
    },
  );

  static final List<ShipEconomyEntry> all = [carrack, fluyte];

  static final Map<String, ShipEconomyEntry> byId = {
    for (final e in all) e.shipTypeId: e,
  };
}

/// True if [unitType] is a ship type (buildable as naval unit, spawns in home fleet).
bool isShipUnitType(String unitType) => ShipEconomyCatalog.byId.containsKey(unitType);
