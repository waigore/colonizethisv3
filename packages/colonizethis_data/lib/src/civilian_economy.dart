import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';
import 'regiment_economy.dart';
import 'ship_economy.dart';

/// Category of unit for BuildUnitOrder validation and resolution.
/// Determined from [unitType] via catalog lookup; distinct from unit roles for existing units.
enum BuildUnitCategory {
  civilian,
  military,
  naval,
  unknown,
}

/// Returns the build order category for [unitType] (single source of truth).
/// Lookup order: Civilian → Military → Naval → Unknown.
BuildUnitCategory buildUnitCategoryForUnitType(String unitType) {
  if (CivilianEconomyCatalog.byId[unitType] != null) return BuildUnitCategory.civilian;
  if (RegimentEconomyCatalog.byId[unitType] != null) return BuildUnitCategory.military;
  if (ShipEconomyCatalog.byId.containsKey(unitType)) return BuildUnitCategory.naval;
  return BuildUnitCategory.unknown;
}

/// Civilian unit training cost configuration.
/// SPEC/game/civilian-units.md
/// SPEC/program/orders.md
class CivilianEconomy {
  const CivilianEconomy({
    required this.id,
    required this.buildTreasuryCost,
    required this.buildInputs,
  });

  /// Civilian unit type id (e.g. 'Builder', 'Engineer', 'Explorer', 'Spy', 'Merchant', 'Rail Builder').
  final String id;

  /// Cash cost to train one civilian of this type (deducted from treasury).
  final int buildTreasuryCost;

  /// Material inputs consumed when training (e.g. paper from stockpile).
  final Map<CommodityId, int> buildInputs;
}

/// Civilian economy catalog. SPEC/game/civilian-units.md.
class CivilianEconomyCatalog {
  CivilianEconomyCatalog._();

  static const int _costCashLow = 1000;
  static const int _costPaperLow = 2;
  static const int _costCashHigh = 2000;
  static const int _costPaperHigh = 4;

  static final CivilianEconomy builder = CivilianEconomy(
    id: kUnitTypeBuilder,
    buildTreasuryCost: _costCashLow,
    buildInputs: {CommodityCatalog.paper.id: _costPaperLow},
  );

  static final CivilianEconomy engineer = CivilianEconomy(
    id: kUnitTypeEngineer,
    buildTreasuryCost: _costCashLow,
    buildInputs: {CommodityCatalog.paper.id: _costPaperLow},
  );

  static final CivilianEconomy explorer = CivilianEconomy(
    id: kUnitTypeExplorer,
    buildTreasuryCost: _costCashLow,
    buildInputs: {CommodityCatalog.paper.id: _costPaperLow},
  );

  static final CivilianEconomy spy = CivilianEconomy(
    id: kUnitTypeSpy,
    buildTreasuryCost: _costCashHigh,
    buildInputs: {CommodityCatalog.paper.id: _costPaperHigh},
  );

  static final CivilianEconomy merchant = CivilianEconomy(
    id: kUnitTypeMerchant,
    buildTreasuryCost: _costCashHigh,
    buildInputs: {CommodityCatalog.paper.id: _costPaperHigh},
  );

  static final CivilianEconomy railBuilder = CivilianEconomy(
    id: kUnitTypeRailBuilder,
    buildTreasuryCost: _costCashHigh,
    buildInputs: {CommodityCatalog.paper.id: _costPaperHigh},
  );

  static final List<CivilianEconomy> all = [
    builder,
    engineer,
    explorer,
    spy,
    merchant,
    railBuilder,
  ];

  static final Map<String, CivilianEconomy> byId = {
    for (final e in all) e.id: e,
  };
}

/// Civilian unit type id → tech id that unlocks it. Absent = buildable from start.
/// SPEC/game/tech-tree-diplomacy-civilian.md, tech-tree-transport.md.
const Map<String, String> unlockingTechByCivilianId = {
  kUnitTypeMerchant: 'merchant_companies',
  kUnitTypeRailBuilder: 'early_steam_engine',
};
