import 'naming_rules.dart';

/// New World tribe naming pools (GDD 09c).
const List<TribeNaming> defaultNamingTribes = [
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
];
