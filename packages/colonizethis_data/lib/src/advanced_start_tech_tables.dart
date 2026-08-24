import 'package:colonizethis_models/colonizethis_models.dart';

import 'tech_extraction.dart';
import 'tech_ids.dart';

/// Fixed 50-turn advanced-start tech ids (23). SPEC/game/advanced-starts.md.
const List<String> kAdvancedStart50TurnTechIds = [
  kTechIdCropRotation,
  kTechIdSawMill,
  kTechIdLandEnclosure,
  kTechIdMineEngineering,
  kTechIdIronMining,
  kTechIdSheepRanching,
  kTechIdWindSawMill,
  kTechIdRoadConstruction,
  kTechIdPrintingPress,
  kTechIdMoneyLending,
  kTechIdDiplomaticExpertise,
  kTechIdMerchantCompanies,
  kTechIdSuperiorHullDesign,
  kTechIdNavigation,
  kTechIdConvoying,
  kTechIdImprovedSailDesign,
  kTechIdOrganisedRegiments,
  kTechIdImprovedIronWeapons,
  kTechIdRecruitSteppeHorsemen,
  kTechIdAnimalHusbandry,
  kTechIdImprovedCavalryTactics,
  kTechIdDiscoveryOfSugar,
  kTechIdDiscoveryOfTobacco,
];

/// Additional tech ids granted at 100-turn (22). Includes all 50-turn ids.
const List<String> kAdvancedStart100TurnAdditionalTechIds = [
  kTechIdCopperAndTinMining,
  kTechIdCoalMining,
  kTechIdSeedDrill,
  kTechIdSquareSetTimbering,
  kTechIdSteamInMining,
  kTechIdEarlySteamEngine,
  kTechIdSugarRefining,
  kTechIdCigarProduction,
  kTechIdApprenticeWorkers,
  kTechIdNationalBureaucracy,
  kTechIdPrivateeringCompanies,
  kTechIdLargeHulls,
  kTechIdImprovedInfantryTactics,
  kTechIdCrucibleProcess,
  kTechIdHussars,
  kTechIdHorseArtillery,
  kTechIdSiegeEngineering,
  kTechIdWeaponCraftsmanship,
  kTechIdDiscoveryOfCotton,
  kTechIdDiscoveryOfFurs,
  kTechIdDiscoveryOfSpices,
  kTechIdDiscoveryOfGoldOrSilver,
];

/// Full 100-turn list (45 techs).
List<String> get kAdvancedStart100TurnTechIds => [
  ...kAdvancedStart50TurnTechIds,
  ...kAdvancedStart100TurnAdditionalTechIds,
];

List<String> advancedStartTechIds(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => const [],
    AdvancedStartType.turns50 => kAdvancedStart50TurnTechIds,
    AdvancedStartType.turns100 => kAdvancedStart100TurnTechIds,
  };
}

/// Validates that every tech in [techIds] exists in the catalog and that each
/// tech's prerequisites are satisfied within [techIds].
void validateAdvancedStartTechList(Iterable<String> techIds) {
  final idSet = techIds.toSet();
  final catalog = techCatalog;
  for (final id in idSet) {
    final def = catalog[id];
    if (def == null) {
      throw StateError('advanced start tech missing from catalog: $id');
    }
    for (final prereq in def.prerequisiteIds) {
      if (!idSet.contains(prereq)) {
        throw StateError(
          'advanced start tech $id missing prerequisite $prereq in same list',
        );
      }
    }
  }
}
