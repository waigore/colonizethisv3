// Shared fixtures for research_extraction_integration_test (Refs #4342 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const researchExtractionPlayerId = 'pl1';
const researchExtractionRegionId = 'oldWorld';
const researchExtractionProvinceId = 'oldWorld|p1';
const researchExtractionGrainTileKey = 'oldWorld|p1|0|0';
const researchExtractionDiscoveryTileKey = 'oldWorld|p1|1|0';

final researchExtractionTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'p1',
      regionId: researchExtractionRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

final researchExtractionTileMapByRegion = {
  researchExtractionRegionId: TileMapResult(
    width: 2,
    height: 1,
    grid: const [
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.grain, null],
    ],
  ),
};

class ResearchExtractionCapIncreaseCase {
  const ResearchExtractionCapIncreaseCase({
    required this.techId,
    required this.prerequisites,
    required this.beforeCap,
    required this.afterCap,
    this.discoveryResourceId,
  });

  final String techId;
  final Set<String> prerequisites;
  final int beforeCap;
  final int afterCap;
  final String? discoveryResourceId;
}

List<ResearchExtractionCapIncreaseCase> researchExtractionCapIncreaseCases() {
  final out = <ResearchExtractionCapIncreaseCase>[];
  for (final tech in techCatalog.values) {
    final prerequisites = tech.prerequisiteIds.toSet();
    final unlockedBefore = {for (final id in prerequisites) id: true};
    final before = extractionCapForResourceForUnlocked(unlockedBefore, 'grain');
    final after = extractionCapForResourceForUnlocked({
      ...unlockedBefore,
      tech.id: true,
    }, 'grain');
    if (after > before) {
      out.add(
        ResearchExtractionCapIncreaseCase(
          techId: tech.id,
          prerequisites: prerequisites,
          beforeCap: before,
          afterCap: after,
          discoveryResourceId: tech.discoveryResourceIds?.isNotEmpty == true
              ? tech.discoveryResourceIds!.first
              : null,
        ),
      );
    }
  }
  out.sort((a, b) => a.techId.compareTo(b.techId));
  return out;
}

Game researchExtractionBuildBaseGame({
  required Set<String> initialUnlockedTechs,
  required String? discoveryResourceId,
}) {
  final unlocked = <String, bool>{
    for (final id in initialUnlockedTechs) id: true,
  };
  final visibilityByTile = <String, String>{
    researchExtractionGrainTileKey: VisibilityLevel.fullyVisible.name,
  };
  final resourceByTileKey = <String, String>{};
  final prospectedTiles = <String>{};

  if (discoveryResourceId != null && discoveryResourceId.isNotEmpty) {
    resourceByTileKey[researchExtractionDiscoveryTileKey] = discoveryResourceId;
    visibilityByTile[researchExtractionDiscoveryTileKey] =
        VisibilityLevel.fullyVisible.name;
    if (kProspectRequiredResourceIds.contains(discoveryResourceId)) {
      prospectedTiles.add(researchExtractionDiscoveryTileKey);
    }
  }

  return Game(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 0,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: researchExtractionProvinceId,
            regionId: researchExtractionRegionId,
            ownerId: researchExtractionPlayerId,
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: TileMapState()
          .setImprovement(researchExtractionGrainTileKey, 4)
          .setRoadLevel(researchExtractionGrainTileKey, 4),
      playerVisibilityByTile: {researchExtractionPlayerId: visibilityByTile},
      playerProspectedTiles: prospectedTiles.isEmpty
          ? const {}
          : {researchExtractionPlayerId: prospectedTiles},
      resourceByTileKey: resourceByTileKey,
    ),
    players: [
      Player(
        id: researchExtractionPlayerId,
        displayName: 'Spain',
        isHuman: true,
        treasury: 5000,
        capitalProvinceId: researchExtractionProvinceId,
        capitalTile: const CapitalTile(
          regionId: researchExtractionRegionId,
          provinceId: researchExtractionProvinceId,
          x: 0,
          y: 0,
        ),
        techUnlocked: unlocked,
      ),
    ],
  );
}

int researchExtractionGrainDelta(Game before, Game after) {
  final beforeQty = before
      .playerById(researchExtractionPlayerId)!
      .stockpile
      .quantityOf(CommodityCatalog.grain.id);
  final afterQty = after
      .playerById(researchExtractionPlayerId)!
      .stockpile
      .quantityOf(CommodityCatalog.grain.id);
  return afterQty - beforeQty;
}
