import 'package:colonizethis_models/colonizethis_models.dart';

import 'tech_catalog.dart';
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

/// Per-tier economy bootstrap values applied to every Great Power.
class AdvancedStartTierParams {
  const AdvancedStartTierParams({
    required this.treasury,
    required this.peasants,
    this.apprentices = 0,
  });

  final int treasury;
  final int peasants;
  final int apprentices;
}

AdvancedStartTierParams advancedStartTierParams(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => const AdvancedStartTierParams(
      treasury: 0,
      peasants: 0,
    ),
    AdvancedStartType.turns50 => const AdvancedStartTierParams(
      treasury: 20000,
      peasants: 16,
    ),
    AdvancedStartType.turns100 => const AdvancedStartTierParams(
      treasury: 40000,
      peasants: 16,
      apprentices: 4,
    ),
  };
}

List<String> advancedStartTechIds(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => const [],
    AdvancedStartType.turns50 => kAdvancedStart50TurnTechIds,
    AdvancedStartType.turns100 => kAdvancedStart100TurnTechIds,
  };
}

/// Validates that every tech in [techIds] exists in the catalog and that each
/// tech's prerequisites are satisfied within [techIds].
/// Civilian unit counts per tier. SPEC/game/advanced-starts.md.
const Map<String, int> kAdvancedStart50TurnCivilianCounts = {
  kUnitTypeExplorer: 3,
  kUnitTypeBuilder: 3,
  kUnitTypeEngineer: 2,
  kUnitTypeSpy: 1,
  kUnitTypeMerchant: 1,
};

const Map<String, int> kAdvancedStart100TurnCivilianCounts = {
  kUnitTypeExplorer: 4,
  kUnitTypeBuilder: 4,
  kUnitTypeEngineer: 3,
  kUnitTypeSpy: 2,
  kUnitTypeMerchant: 2,
  kUnitTypeRailBuilder: 1,
};

Map<String, int> advancedStartCivilianCounts(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => const {},
    AdvancedStartType.turns50 => kAdvancedStart50TurnCivilianCounts,
    AdvancedStartType.turns100 => kAdvancedStart100TurnCivilianCounts,
  };
}

int advancedStartRegimentCount(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 6,
    AdvancedStartType.turns100 => 12,
  };
}

/// Fixed minimum cargo ships per tier. 100-turn dynamic formula applies after NW dev.
int advancedStartCargoShipCount(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 1,
    AdvancedStartType.turns100 => 6,
  };
}

/// Advanced-start cargo ship type id (Galleon per SPEC/game/advanced-starts.md).
const String kAdvancedStartCargoShipTypeId = 'galleon';

/// NW province reveal target (50-turn: midpoint of 50–75% range). SPEC/game/advanced-starts.md.
const double kAdvancedStart50TurnNwRevealFraction = 0.625;

const double kAdvancedStart100TurnNwRevealFraction = 1.0;

const double kAdvancedStart50TurnProspectFraction = 0.50;

const double kAdvancedStart100TurnProspectFraction = 0.75;

/// NW provinces assigned per GP at 100-turn advanced start.
const int kAdvancedStart100TurnNwColonizationCount = 6;

const double kAdvancedStart50TurnDevelopmentFraction = 0.25;

const double kAdvancedStart100TurnDevelopmentFraction = 0.50;

/// Non-prospect resource ids eligible for advanced-start development.
const Set<String> kAdvancedStartDevelopableResourceIds = {
  'grain',
  'meat',
  'wool',
  'horses',
  'timber',
  'sugarCane',
  'tobacco',
  'cotton',
  'furs',
  'spices',
};

double advancedStartNwRevealFraction(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => kAdvancedStart50TurnNwRevealFraction,
    AdvancedStartType.turns100 => kAdvancedStart100TurnNwRevealFraction,
  };
}

double advancedStartProspectFraction(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => kAdvancedStart50TurnProspectFraction,
    AdvancedStartType.turns100 => kAdvancedStart100TurnProspectFraction,
  };
}

double advancedStartDevelopmentFraction(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => kAdvancedStart50TurnDevelopmentFraction,
    AdvancedStartType.turns100 => kAdvancedStart100TurnDevelopmentFraction,
  };
}

int advancedStartNwColonizationCount(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 0,
    AdvancedStartType.turns100 => kAdvancedStart100TurnNwColonizationCount,
  };
}

/// Lower rank = higher selection priority (food, then luxury, timber, minerals).
int advancedStartDevelopableTilePriority(String resourceId) {
  return switch (resourceId) {
    'grain' || 'meat' => 0,
    'wool' ||
    'horses' ||
    'sugarCane' ||
    'tobacco' ||
    'cotton' ||
    'furs' ||
    'spices' =>
      1,
    'timber' => 2,
    _ => 3,
  };
}

OvertureStage advancedStartDiplomacyOvertureStage(AdvancedStartType type) {
  return switch (type) {
    AdvancedStartType.none => OvertureStage.none,
    AdvancedStartType.turns50 => OvertureStage.tradeConsulate,
    AdvancedStartType.turns100 => OvertureStage.embassy,
  };
}

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
