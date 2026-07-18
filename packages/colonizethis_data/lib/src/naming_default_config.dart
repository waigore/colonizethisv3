part of 'naming_rules.dart';

/// Default historically inspired naming config (program-level; current product).
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
      provinceNamePool: [
        'Papal States',
        'Venice',
        'Milan',
        'Naples',
        'Tuscany',
      ],
    ),
    MinorNationNaming(
      id: 'minor2',
      displayName: 'Germany',
      provinceNamePool: [
        'Bavaria',
        'Saxony',
        'Brandenburg',
        'Hanover',
        'Palatinate',
      ],
    ),
    MinorNationNaming(
      id: 'minor3',
      displayName: 'Austria',
      provinceNamePool: [
        'Lower Austria',
        'Upper Austria',
        'Styria',
        'Tyrol',
        'Carinthia',
      ],
    ),
    MinorNationNaming(
      id: 'minor4',
      displayName: 'Poland',
      provinceNamePool: [
        'Greater Poland',
        'Lesser Poland',
        'Mazovia',
        'Lithuania',
        'Livonia',
      ],
    ),
    MinorNationNaming(
      id: 'minor5',
      displayName: 'Denmark',
      provinceNamePool: ['Sjælland', 'Jutland', 'Skåne', 'Norway', 'Iceland'],
    ),
    MinorNationNaming(
      id: 'minor6',
      displayName: 'Scotland',
      provinceNamePool: [
        'Lothian',
        'Fife',
        'Strathclyde',
        'Grampian',
        'Highlands',
      ],
    ),
  ],
  tribes: [
    // GDD 09c — New World Tribes. Capital province gets first in pool.
    TribeNaming(
      id: 'tribe1',
      displayName: 'Aztec',
      provinceNamePool: [
        'Mexica',
        'Acolhua',
        'Tepanec',
        'Tlaxcala',
        'Cuauhnahuac',
      ],
    ),
    TribeNaming(
      id: 'tribe2',
      displayName: 'Maya',
      provinceNamePool: ['Cupul', 'Cocom', "K'iche'", 'Kaqchikel', 'Mopan'],
    ),
    TribeNaming(
      id: 'tribe3',
      displayName: 'Inca',
      provinceNamePool: [
        'Cuzco',
        'Chinchaysuyu',
        'Antisuyu',
        'Qullasuyu',
        'Kuntisuyu',
      ],
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
      provinceNamePool: [
        'Powhatan',
        'Pamunkey',
        'Chickahominy',
        'Appomattoc',
        'Weanoc',
      ],
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
