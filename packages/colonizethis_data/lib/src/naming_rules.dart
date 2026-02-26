import 'package:meta/meta.dart';

/// A leader variant for a Great Power. GDD 09. Each variant has distinct
/// bonuses and optionally a distinct province pool (e.g. Prussia's two variants).
@immutable
class LeaderVariant {
  const LeaderVariant({
    required this.id,
    required this.name,
    required this.leaderKey,
    required this.provinceNamePool,
  });

  final String id;
  final String name;
  final String leaderKey;
  /// Homeland province names (9 non-capital). Capital applied separately.
  final List<String> provinceNamePool;
}

/// Resolved naming configuration for the active ruleset.
///
/// SPEC/game/naming.md, SPEC/program/ruleset-config.md.
@immutable
class GreatPowerNaming {
  const GreatPowerNaming({
    required this.id,
    required this.countryName,
    required this.adjective,
    required this.capitalCityName,
    required this.leaderVariants,
  });

  final String id;
  final String countryName;
  final String adjective;
  final String capitalCityName;
  final List<LeaderVariant> leaderVariants;

  LeaderVariant variantById(String variantId) =>
      leaderVariants.firstWhere(
        (v) => v.id == variantId,
        orElse: () => leaderVariants.first,
      );

  bool get hasMultipleVariants => leaderVariants.length > 1;

  String get defaultLeaderVariantId => leaderVariants.first.id;
}

@immutable
class MinorNationNaming {
  const MinorNationNaming({
    required this.id,
    required this.displayName,
    this.provinceNamePool = const [],
  });

  final String id;
  final String displayName;
  final List<String> provinceNamePool;
}

@immutable
class TribeNaming {
  const TribeNaming({
    required this.id,
    required this.displayName,
    this.provinceNamePool = const [],
  });

  final String id;
  final String displayName;
  final List<String> provinceNamePool;
}

@immutable
class ResolvedNamingConfig {
  const ResolvedNamingConfig({
    required this.greatPowers,
    required this.minorNations,
    required this.tribes,
  });

  final List<GreatPowerNaming> greatPowers;
  final List<MinorNationNaming> minorNations;
  final List<TribeNaming> tribes;

  GreatPowerNaming? gpById(String id) =>
      greatPowers.firstWhere((g) => g.id == id, orElse: () => _emptyGp).id.isEmpty
          ? null
          : greatPowers.firstWhere((g) => g.id == id);

  static const GreatPowerNaming _emptyGp = GreatPowerNaming(
    id: '',
    countryName: '',
    adjective: '',
    capitalCityName: '',
    leaderVariants: [],
  );

  String defaultLeaderVariantId(String gpId) {
    final gp = gpById(gpId);
    if (gp == null || gp.leaderVariants.isEmpty) return '';
    return gp.leaderVariants.first.id;
  }

  bool hasMultipleLeaderVariants(String gpId) {
    final gp = gpById(gpId);
    return gp != null && gp.leaderVariants.length > 1;
  }

  MinorNationNaming? minorById(String id) =>
      minorNations.firstWhere((m) => m.id == id, orElse: () => const MinorNationNaming(
            id: '',
            displayName: '',
          )).id.isEmpty
          ? null
          : minorNations.firstWhere((m) => m.id == id);

  TribeNaming? tribeById(String id) =>
      tribes.firstWhere((t) => t.id == id, orElse: () => const TribeNaming(
            id: '',
            displayName: '',
            provinceNamePool: [],
          )).id.isEmpty
          ? null
          : tribes.firstWhere((t) => t.id == id);
}

/// All selectable Great Power semantic ids. GDD 09. Each GP appears at most once per game.
const List<String> allGreatPowerIds = [
  'england',
  'france',
  'spain',
  'portugal',
  'netherlands',
  'prussia',
  'sweden',
];

/// Prussia leader variant ids.
const String prussiaVariantFrederickTheGreat = 'frederick_the_great';
const String prussiaVariantFrederickWilliam = 'frederick_william';

/// Default historically inspired naming config for the MVP ruleset.
///
/// This is a program-level stand-in for a future JSON-driven ruleset; it is
/// deterministic and aligned with the Great Power identities from GDD 09.
const ResolvedNamingConfig defaultNamingConfig = ResolvedNamingConfig(
  greatPowers: [
    GreatPowerNaming(
      id: 'england',
      countryName: 'England',
      adjective: 'English',
      capitalCityName: 'London',
      leaderVariants: [
        LeaderVariant(
          id: 'queen_victoria',
          name: 'Queen Victoria',
          leaderKey: 'england_leader',
          provinceNamePool: [
            'Kent',
            'Yorkshire',
            'Lancashire',
            'Cornwall',
            'East Anglia',
            'Wessex',
            'Northumberland',
            'Gloucestershire',
            'Lincolnshire',
          ],
        ),
      ],
    ),
    GreatPowerNaming(
      id: 'france',
      countryName: 'France',
      adjective: 'French',
      capitalCityName: 'Paris',
      leaderVariants: [
        LeaderVariant(
          id: 'napoleon',
          name: 'Napoleon Bonaparte',
          leaderKey: 'france_leader',
          provinceNamePool: [
            'Normandy',
            'Brittany',
            'Guyenne',
            'Languedoc',
            'Provence',
            'Burgundy',
            'Champagne',
            'Picardy',
            'Dauphiné',
          ],
        ),
      ],
    ),
    GreatPowerNaming(
      id: 'spain',
      countryName: 'Spain',
      adjective: 'Spanish',
      capitalCityName: 'Madrid',
      leaderVariants: [
        LeaderVariant(
          id: 'isabella',
          name: 'Queen Isabella I',
          leaderKey: 'spain_leader',
          provinceNamePool: [
            'Old Castile',
            'Aragon',
            'Catalonia',
            'Andalusia',
            'Valencia',
            'Galicia',
            'Navarre',
            'Granada',
            'León',
          ],
        ),
      ],
    ),
    GreatPowerNaming(
      id: 'portugal',
      countryName: 'Portugal',
      adjective: 'Portuguese',
      capitalCityName: 'Lisbon',
      leaderVariants: [
        LeaderVariant(
          id: 'henry_navigator',
          name: 'Prince Henry the Navigator',
          leaderKey: 'portugal_leader',
          provinceNamePool: [
            'Beira',
            'Alentejo',
            'Algarve',
            'Minho',
            'Trás-os-Montes',
            'Douro Litoral',
            'Ribatejo',
            'Beira Baixa',
            'Estremadura do Norte',
          ],
        ),
      ],
    ),
    GreatPowerNaming(
      id: 'netherlands',
      countryName: 'Netherlands',
      adjective: 'Dutch',
      capitalCityName: 'Amsterdam',
      leaderVariants: [
        LeaderVariant(
          id: 'de_ruyter',
          name: 'Michiel de Ruyter',
          leaderKey: 'netherlands_leader',
          provinceNamePool: [
            'Zeeland',
            'Utrecht',
            'Friesland',
            'Groningen',
            'Overijssel',
            'Gelderland',
            'Drenthe',
            'Flanders',
            'Brabant',
          ],
        ),
      ],
    ),
    GreatPowerNaming(
      id: 'prussia',
      countryName: 'Prussia',
      adjective: 'Prussian',
      capitalCityName: 'Berlin',
      leaderVariants: [
        LeaderVariant(
          id: prussiaVariantFrederickTheGreat,
          name: 'Frederick the Great',
          leaderKey: 'prussia_leader',
          provinceNamePool: [
            'Pomerania',
            'Silesia',
            'East Prussia',
            'Magdeburg',
            'Halberstadt',
            'Minden',
            'Ravensberg',
            'Neumark',
            'Jülich-Cleves',
          ],
        ),
        LeaderVariant(
          id: prussiaVariantFrederickWilliam,
          name: 'Frederick William',
          leaderKey: 'prussia_reserve_leader',
          provinceNamePool: [
            'Prussia',
            'Pomerania',
            'Farther Pomerania',
            'Magdeburg',
            'Halberstadt',
            'Minden',
            'Ravensberg',
            'Neumark',
            'Jülich-Cleves',
          ],
        ),
      ],
    ),
    GreatPowerNaming(
      id: 'sweden',
      countryName: 'Sweden',
      adjective: 'Swedish',
      capitalCityName: 'Stockholm',
      leaderVariants: [
        LeaderVariant(
          id: 'gustavus',
          name: 'Gustavus Adolphus',
          leaderKey: 'sweden_leader',
          provinceNamePool: [
            'Västmanland',
            'Skåne',
            'Östergötland',
            'Västergötland',
            'Småland',
            'Dalarna',
            'Norrland',
            'Finland',
            'Estonia',
          ],
        ),
      ],
    ),
  ],
  minorNations: [
    // GDD 09b — Minor Nations. Capital province gets first in pool.
    MinorNationNaming(
      id: 'minor1',
      displayName: 'Italy',
      provinceNamePool: ['Papal States', 'Venice', 'Milan', 'Naples', 'Tuscany'],
    ),
    MinorNationNaming(
      id: 'minor2',
      displayName: 'Germany',
      provinceNamePool: ['Bavaria', 'Saxony', 'Brandenburg', 'Hanover', 'Palatinate'],
    ),
    MinorNationNaming(
      id: 'minor3',
      displayName: 'Austria',
      provinceNamePool: ['Lower Austria', 'Upper Austria', 'Styria', 'Tyrol', 'Carinthia'],
    ),
    MinorNationNaming(
      id: 'minor4',
      displayName: 'Poland',
      provinceNamePool: ['Greater Poland', 'Lesser Poland', 'Mazovia', 'Lithuania', 'Livonia'],
    ),
    MinorNationNaming(
      id: 'minor5',
      displayName: 'Denmark',
      provinceNamePool: ['Sjælland', 'Jutland', 'Skåne', 'Norway', 'Iceland'],
    ),
    MinorNationNaming(
      id: 'minor6',
      displayName: 'Scotland',
      provinceNamePool: ['Lothian', 'Fife', 'Strathclyde', 'Grampian', 'Highlands'],
    ),
  ],
  tribes: [
    // GDD 09c — New World Tribes. Capital province gets first in pool.
    TribeNaming(
      id: 'tribe1',
      displayName: 'Aztec',
      provinceNamePool: ['Mexica', 'Acolhua', 'Tepanec', 'Tlaxcala', 'Cuauhnahuac'],
    ),
    TribeNaming(
      id: 'tribe2',
      displayName: 'Maya',
      provinceNamePool: ['Cupul', 'Cocom', "K'iche'", 'Kaqchikel', 'Mopan'],
    ),
    TribeNaming(
      id: 'tribe3',
      displayName: 'Inca',
      provinceNamePool: ['Cuzco', 'Chinchaysuyu', 'Antisuyu', 'Qullasuyu', 'Kuntisuyu'],
    ),
    TribeNaming(
      id: 'tribe4',
      displayName: 'Muisca',
      provinceNamePool: ['Bacatá', 'Hunza', 'Iraca', 'Tundama', 'Ubaque'],
    ),
    TribeNaming(
      id: 'tribe5',
      displayName: 'Taíno',
      provinceNamePool: ['Maguana', 'Marién', 'Xaragua', 'Boriquén', 'Cibao'],
    ),
    TribeNaming(
      id: 'tribe6',
      displayName: 'Powhatan',
      provinceNamePool: ['Powhatan', 'Pamunkey', 'Chickahominy', 'Appomattoc', 'Weanoc'],
    ),
    TribeNaming(
      id: 'tribe7',
      displayName: 'Iroquois',
      provinceNamePool: ['Mohawk', 'Oneida', 'Onondaga', 'Cayuga', 'Seneca'],
    ),
    TribeNaming(
      id: 'tribe8',
      displayName: 'Cherokee',
      provinceNamePool: ['Overhill', 'Valley', 'Middle', 'Lower', 'Out Towns'],
    ),
    TribeNaming(
      id: 'tribe9',
      displayName: 'Sioux',
      provinceNamePool: ['Santee', 'Wahpeton', 'Sisseton', 'Yankton', 'Teton'],
    ),
    TribeNaming(
      id: 'tribe10',
      displayName: 'Mapuche',
      provinceNamePool: ['Arauco', 'Malleco', 'Toltén', 'Bio-Bio', 'Cautín'],
    ),
  ],
);
