import 'package:colonizethis_models/colonizethis_models.dart';

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
