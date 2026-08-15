import 'naming_rules.dart';

/// Minor-nation naming pools (GDD 09b).
const List<MinorNationNaming> defaultNamingMinors = [
  // GDD 09b — Minor Nations. Capital province gets first in pool.
  MinorNationNaming(
    id: 'minor1',
    displayName: 'Italy',
    provinceNamePool: ['Papal States', 'Venice', 'Milan', 'Naples', 'Tuscany'],
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
];
