import 'regiment_economy_model.dart';
import 'regiment_economy_era1.dart';
import 'regiment_economy_era2.dart';
import 'regiment_economy_era3.dart';
import 'regiment_economy_era4.dart';

/// Regiment economy catalog façade. Era libraries hold row data; this class
/// preserves the stable public surface (Refs #4292).
class RegimentEconomyCatalog {
  RegimentEconomyCatalog._();

  // Era 1
  static final RegimentEconomy peasantLevies =
      RegimentEconomyEra1.peasantLevies;
  static final RegimentEconomy pikemen = RegimentEconomyEra1.pikemen;
  static final RegimentEconomy arquebusiers = RegimentEconomyEra1.arquebusiers;
  static final RegimentEconomy bowmen = RegimentEconomyEra1.bowmen;
  static final RegimentEconomy squires = RegimentEconomyEra1.squires;
  static final RegimentEconomy knights = RegimentEconomyEra1.knights;
  static final RegimentEconomy culverin = RegimentEconomyEra1.culverin;

  // Era 2
  static final RegimentEconomy calivermen = RegimentEconomyEra2.calivermen;
  static final RegimentEconomy halberdiers = RegimentEconomyEra2.halberdiers;
  static final RegimentEconomy musketeers = RegimentEconomyEra2.musketeers;
  static final RegimentEconomy cossacks = RegimentEconomyEra2.cossacks;
  static final RegimentEconomy lancers = RegimentEconomyEra2.lancers;
  static final RegimentEconomy harquebusiers = RegimentEconomyEra2.harquebusiers;
  static final RegimentEconomy horseArtillery = RegimentEconomyEra2.horseArtillery;
  static final RegimentEconomy royalArtillery = RegimentEconomyEra2.royalArtillery;

  // Era 3
  static final RegimentEconomy skirmishers = RegimentEconomyEra3.skirmishers;
  static final RegimentEconomy regulars = RegimentEconomyEra3.regulars;
  static final RegimentEconomy grenadiers = RegimentEconomyEra3.grenadiers;
  static final RegimentEconomy hussars = RegimentEconomyEra3.hussars;
  static final RegimentEconomy cuirassiers = RegimentEconomyEra3.cuirassiers;
  static final RegimentEconomy lightArtillery = RegimentEconomyEra3.lightArtillery;
  static final RegimentEconomy heavyArtillery = RegimentEconomyEra3.heavyArtillery;

  // Era 4
  static final RegimentEconomy sharpshooters = RegimentEconomyEra4.sharpshooters;
  static final RegimentEconomy rifleInfantry = RegimentEconomyEra4.rifleInfantry;
  static final RegimentEconomy guards = RegimentEconomyEra4.guards;
  static final RegimentEconomy scouts = RegimentEconomyEra4.scouts;
  static final RegimentEconomy carbineCavalry = RegimentEconomyEra4.carbineCavalry;
  static final RegimentEconomy fieldArtillery = RegimentEconomyEra4.fieldArtillery;
  static final RegimentEconomy siegeGuns = RegimentEconomyEra4.siegeGuns;

  /// All regiment economy entries, one per regiment type.
  static final List<RegimentEconomy> all = [
    ...RegimentEconomyEra1.all,
    ...RegimentEconomyEra2.all,
    ...RegimentEconomyEra3.all,
    ...RegimentEconomyEra4.all,
  ];

  /// Fast lookup by regiment id.
  static final Map<String, RegimentEconomy> byId = {
    for (final e in all) e.id: e,
  };
}
