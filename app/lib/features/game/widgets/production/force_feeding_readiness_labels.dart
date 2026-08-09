// Localized forces-food copy shared by Production and decision-point soft warns.
// SPEC/ui/production-panel.md § Forces food readiness; Refs #4242.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

String landForceFeedingDefaultLine(
  AppLocalizations l10n,
  ForceFeedingSnapshot snapshot,
) {
  return switch (snapshot.landCombatTier) {
    ForceFeedingCombatTier.full => l10n.production_forcesFoodArmiesFullyFed,
    ForceFeedingCombatTier.moderate =>
      l10n.production_forcesFoodArmiesUnderfedModerate,
    ForceFeedingCombatTier.severe =>
      l10n.production_forcesFoodArmiesUnderfedSevere,
  };
}

String navalForceFeedingDefaultLine(
  AppLocalizations l10n,
  ForceFeedingSnapshot snapshot,
) {
  return switch (snapshot.navalCombatTier) {
    ForceFeedingCombatTier.full => l10n.production_forcesFoodFleetsFullyFed,
    ForceFeedingCombatTier.moderate =>
      l10n.production_forcesFoodFleetsUnderfedModerate,
    ForceFeedingCombatTier.severe =>
      l10n.production_forcesFoodFleetsUnderfedSevere,
  };
}

/// Soft-warn copy for invasion/combat when land forces are underfed.
String? landForceFeedingSoftWarning(
  AppLocalizations l10n,
  ForceFeedingSnapshot snapshot,
) {
  if (!snapshot.hasLandForces || snapshot.isLandFullyFed) {
    return null;
  }
  return switch (snapshot.landCombatTier) {
    ForceFeedingCombatTier.full => null,
    ForceFeedingCombatTier.moderate =>
      l10n.forcesFood_landUnderfedModerateWarning,
    ForceFeedingCombatTier.severe => l10n.forcesFood_landUnderfedSevereWarning,
  };
}
