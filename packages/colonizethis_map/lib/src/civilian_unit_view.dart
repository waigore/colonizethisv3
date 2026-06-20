/// Civilian unit classification and icon-priority helpers for map overlays
/// (Refs #3459).
///
/// Canonical site for civilian type normalization and stacking priority used
/// when building init-game map view civilian tile markers.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

/// Normalizes a civilian unit type id for priority lookup (case and separators).
String normalizeCivilianUnitTypeForPriority(String type) {
  return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}

/// Lower number = higher icon priority when multiple civilians share a tile.
int civilianUnitIconPriorityForType(String type) {
  final normalized = normalizeCivilianUnitTypeForPriority(type);
  switch (normalized) {
    case 'builder':
      return 0;
    case 'engineer':
      return 1;
    case 'railbuilder':
      return 2;
    case 'explorer':
      return 3;
    case 'merchant':
      return 4;
    case 'spy':
      return 5;
    default:
      return 999;
  }
}

/// Returns true when [unitType] is a non-military, non-naval unit role.
bool isCivilianUnitType(String unitType) {
  final role = unitRoleForType(unitType);
  if (role == null) {
    return false;
  }
  return role != UnitRole.military && role != UnitRole.naval;
}
