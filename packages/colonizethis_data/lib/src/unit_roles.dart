import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_config.dart';

/// High-level unit roles used by validation and combat.
enum UnitRole { military, civilianWorker, explorer, merchant, spy, naval }

/// Explicit role mapping for non-military units.
///
/// Military regiments are derived from [regimentStatsById] instead of being
/// listed here.
const Map<String, UnitRole> _explicitUnitRoles = {
  kUnitTypeExplorer: UnitRole.explorer,
  kUnitTypeBuilder: UnitRole.civilianWorker,
  kUnitTypeEngineer: UnitRole.civilianWorker,
  kUnitTypeSpy: UnitRole.spy,
  kUnitTypeMerchant: UnitRole.merchant,
  kUnitTypeRailBuilder: UnitRole.civilianWorker,
};

/// Returns the [UnitRole] for a given unit [type] id, or null if unknown.
UnitRole? unitRoleForType(String type) {
  final explicit = _explicitUnitRoles[type];
  if (explicit != null) return explicit;

  // If this is a known regiment id, treat as military.
  final stats = regimentStatsById(type);
  if (stats != null) return UnitRole.military;

  return null;
}

bool isMilitaryUnit(String type) => unitRoleForType(type) == UnitRole.military;

bool isExplorerUnit(String type) => unitRoleForType(type) == UnitRole.explorer;

bool isCivilianWorkerUnit(String type) =>
    unitRoleForType(type) == UnitRole.civilianWorker;

bool isMerchantUnit(String type) => unitRoleForType(type) == UnitRole.merchant;

bool isSpyUnit(String type) => unitRoleForType(type) == UnitRole.spy;

bool isNavalUnit(String type) => unitRoleForType(type) == UnitRole.naval;

/// Returns true if this unit type can participate as a combatant.
///
/// Currently only military units can initiate or participate in combat.
bool canUnitInitiateCombat(String type) => isMilitaryUnit(type);
