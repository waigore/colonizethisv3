part of 'order_engine_validate_work_expectations.dart';

void _rejectsBuildImprovementOnMineralTileWhenNotProspected() {
  vwExpectMineralBuildImprovementRejectedWhenNotProspected();
}

void _acceptsBuildImprovementOnMineralTileAfterProspected() {
  vwExpectMineralBuildImprovementAcceptedWhenProspected();
}

void _acceptsBuildImprovementOnGrainWhenTileNotProspected() {
  vwExpectGrainBuildImprovementAcceptedWhenNotProspected();
}

void _rejectsBuildImprovementWhenTileHasNoResource() {
  vwExpectBuildImprovementRejectedNoResource();
}

void _rejectsBuildImprovementWhenImprovementLevelAlready4() {
  vwExpectBuildImprovementRejectedAtLevel4();
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceededEmptyTech() {
  vwExpectEmptyTechCapBuildImprovementRejected();
}

void _rejectsBuildImprovementWhenTechCapWouldBeExceeded() {
  vwExpectTechCapBuildImprovementRejected();
}

void _acceptsGrainUpgradeWhenExactNextLevelGrainTechIsUnlocked() {
  vwExpectGrainUpgradeWithLandEnclosure();
}

void _acceptsBuildImprovementWhenTileHasResourceLevel4TechCapAllows() {
  vwExpectBuildImprovementAcceptedAtLevel4TechCap();
}

void _rejectsBuildImprovementInForeignUnpurchasedProvince() {
  vwExpectBuildImprovementRejectedForeignUnpurchased();
}

void _rejectsRaisingScrubTimberFromLevel1EvenWithCircularSaw() {
  vwExpectScrubTimberRejected(
    level: 1,
    terrain: TerrainType.scrubForest,
  );
}

void _acceptsRaisingHardwoodTimberFromLevel1WithCircularSaw() {
  vwExpectScrubTimberAccepted(
    level: 1,
    terrain: TerrainType.hardwoodForest,
  );
}

void _acceptsInitialScrubTimberImprovementLevel01() {
  vwExpectScrubTimberAccepted(
    level: 0,
    terrain: TerrainType.scrubForest,
  );
}

void _acceptsBuildImprovementOnPurchasedTileInForeignProvince() {
  vwExpectBuildImprovementAcceptedOnPurchasedForeignTile();
}

void _rejectsBuildFortToLevel2WithoutMineEngineering() {
  vwExpectFortLevel2RejectedWithoutMineEngineering();
}

void _rejectsBuildFortToLevel3WithoutModernForts() {
  vwExpectFortLevel3RejectedWithoutModernForts();
}

void _rejectsBuildRailWhenTileTerrainDataIsMissing() {
  vwExpectRailMissingTerrainDataRejected();
}

void _rejectsBuildRailWhenRoadLevelIs0() {
  vwExpectRailTerrainRejected(
    terrain: TerrainType.plains,
    roadLevel: 0,
  );
}

void _rejectsBuildRailOnHillsWithOnlyEarlySteam() {
  vwExpectRailTerrainRejected(
    terrain: TerrainType.hills,
    techUnlocked: const {kTechIdEarlySteamEngine: true},
    reasonContains: 'Later Steam',
  );
}

void _acceptsBuildRailOnPlainsWithEarlySteamAndRoad1() {
  vwExpectRailTerrainAccepted(terrain: TerrainType.plains);
}

void _rejectsBuildRoadInMinorProvinceWithoutEmbassyPath() {
  vwExpectMinorProvinceRoadRejectedWithoutEmbassy();
}

void
_rejectsBuildRoadInMinorProvinceEvenWithEmbassyWhenOccupancyDisallowsTile() {
  vwExpectMinorProvinceRoadRejectedDespiteEmbassy();
}

void _rejectsUpgradeTownWithoutNationalBureaucracy() {
  vwExpectUpgradeTownOutcome(
    techUnlocked: const {},
    accepted: false,
    reasonContains: 'National Bureaucracy',
  );
}

void _acceptsUpgradeTownWhenNationalBureaucracyUnlocked() {
  vwExpectUpgradeTownOutcome(
    techUnlocked: const {kTechIdNationalBureaucracy: true},
    accepted: true,
  );
}
