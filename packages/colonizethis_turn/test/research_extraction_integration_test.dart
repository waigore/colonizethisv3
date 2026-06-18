import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Research to extraction cap integration', () {
    final cases = _capIncreaseCases();

    test('contains at least one cap-increase tech case', () {
      expect(cases, isNotEmpty);
    });

    for (final testCase in cases) {
      test(
        '${testCase.techId}: cap ${testCase.beforeCap} -> ${testCase.afterCap} applies next turn',
        () {
          final baseGame = _buildBaseGame(
            initialUnlockedTechs: testCase.prerequisites,
            discoveryResourceId: testCase.discoveryResourceId,
          );

          // Turn A: baseline extraction with pre-research cap.
          final afterBaseline = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: baseGame,
              topology: _topology,
              orders: const Orders(),
              tileMapByRegion: _tileMapByRegion,
              defaultAssignments: const [],
            ),
          );
          final baselineDelta = _grainDelta(baseGame, afterBaseline);
          expect(
            baselineDelta,
            testCase.beforeCap,
            reason:
                'Extraction ignoring baseline cap before researching ${testCase.techId}',
          );

          // Seed progress just below the (rebalanced) cost so a single
          // maximum-funding turn unlocks the tech regardless of its cost tier,
          // keeping this test focused on the cap-applies-next-turn behavior
          // rather than research pacing. SPEC/game/tech-tree.md § Research Model.
          final seededProgress = techById(testCase.techId)!.cost - 1;
          final researchInput = afterBaseline.copyWith(
            players: [
              for (final p in afterBaseline.players)
                p.id == _playerId
                    ? p.copyWith(
                        researchProgressByTechId: {
                          testCase.techId: seededProgress,
                        },
                      )
                    : p,
            ],
          );

          // Turn B: research resolves this turn; extraction still uses previous cap.
          final withResearch = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: researchInput,
              topology: _topology,
              orders: Orders(
                researchOrdersByPlayerId: {
                  _playerId: [
                    ResearchOrder(
                      slotIndex: 0,
                      techId: testCase.techId,
                      funding: ResearchFundingLevel.maximum,
                    ),
                  ],
                },
              ),
              tileMapByRegion: _tileMapByRegion,
              defaultAssignments: const [],
            ),
          );

          final researchedPlayer = withResearch.playerById(_playerId)!;
          expect(
            researchedPlayer.techUnlocked?[testCase.techId],
            isTrue,
            reason:
                'Cap not updated after research: expected ${testCase.techId} to unlock in research phase',
          );

          // Turn C: extraction must now use the updated cap.
          final afterUpgradeExtraction = requireTurnResolutionComplete(
            resolveTurnForGame(
              game: withResearch,
              topology: _topology,
              orders: const Orders(),
              tileMapByRegion: _tileMapByRegion,
              defaultAssignments: const [],
            ),
          );
          final postUpgradeDelta = _grainDelta(
            withResearch,
            afterUpgradeExtraction,
          );
          expect(
            postUpgradeDelta,
            testCase.afterCap,
            reason:
                'Extraction ignoring updated cap after ${testCase.techId} was researched',
          );
        },
      );
    }
  });
}

const String _playerId = 'pl1';
const String _regionId = 'oldWorld';
const String _provinceId = 'oldWorld|p1';
const String _grainTileKey = 'oldWorld|p1|0|0';
const String _discoveryTileKey = 'oldWorld|p1|1|0';

final MapTopology _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'p1',
      regionId: _regionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

final Map<String, TileMapResult> _tileMapByRegion = {
  _regionId: TileMapResult(
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

class _CapIncreaseCase {
  const _CapIncreaseCase({
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

List<_CapIncreaseCase> _capIncreaseCases() {
  final out = <_CapIncreaseCase>[];
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
        _CapIncreaseCase(
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

Game _buildBaseGame({
  required Set<String> initialUnlockedTechs,
  required String? discoveryResourceId,
}) {
  final unlocked = <String, bool>{
    for (final id in initialUnlockedTechs) id: true,
  };
  final visibilityByTile = <String, String>{
    _grainTileKey: VisibilityLevel.fullyVisible.name,
  };
  final resourceByTileKey = <String, String>{};
  final prospectedTiles = <String>{};

  if (discoveryResourceId != null && discoveryResourceId.isNotEmpty) {
    resourceByTileKey[_discoveryTileKey] = discoveryResourceId;
    visibilityByTile[_discoveryTileKey] = VisibilityLevel.fullyVisible.name;
    if (kProspectRequiredResourceIds.contains(discoveryResourceId)) {
      prospectedTiles.add(_discoveryTileKey);
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
            id: _provinceId,
            regionId: _regionId,
            ownerId: _playerId,
            townDevelopmentLevel: 4,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: TileMapState()
          .setImprovement(_grainTileKey, 4)
          .setRoadLevel(_grainTileKey, 4),
      playerVisibilityByTile: {_playerId: visibilityByTile},
      playerProspectedTiles: prospectedTiles.isEmpty
          ? const {}
          : {_playerId: prospectedTiles},
      resourceByTileKey: resourceByTileKey,
    ),
    players: [
      Player(
        id: _playerId,
        displayName: 'Spain',
        isHuman: true,
        treasury: 5000,
        capitalProvinceId: _provinceId,
        capitalTile: const CapitalTile(
          regionId: _regionId,
          provinceId: _provinceId,
          x: 0,
          y: 0,
        ),
        techUnlocked: unlocked,
      ),
    ],
  );
}

int _grainDelta(Game before, Game after) {
  final beforeQty = before
      .playerById(_playerId)!
      .stockpile
      .quantityOf(CommodityCatalog.grain.id);
  final afterQty = after
      .playerById(_playerId)!
      .stockpile
      .quantityOf(CommodityCatalog.grain.id);
  return afterQty - beforeQty;
}
