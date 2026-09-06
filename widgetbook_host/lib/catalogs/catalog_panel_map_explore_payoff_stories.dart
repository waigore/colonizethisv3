// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Explore payoff overlay stories
// (Refs #4733).
part of 'catalog.dart';

/// MAP20001 Tile **Explore** payoff gist use cases. Refs #4733.
List<WidgetbookUseCase> get provinceOverlayExplorePayoffUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Explore payoff one turn',
    builder: (context) => _provinceOverlayExplorePayoffStory(
      targetTiles: const ['oldWorld|p1|0|0'],
      otherTiles: const [
        'oldWorld|p2|0|0',
        'oldWorld|p2|1|0',
        'oldWorld|p2|2|0',
      ],
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Explore payoff three turns',
    builder: (context) => _provinceOverlayExplorePayoffStory(
      targetTiles: const [
        'oldWorld|p1|0|0',
        'oldWorld|p1|1|0',
        'oldWorld|p1|2|0',
      ],
      otherTiles: const ['oldWorld|p2|0|0'],
    ),
  ),
];

Widget _provinceOverlayExplorePayoffStory({
  required List<String> targetTiles,
  required List<String> otherTiles,
}) {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  final game = Game(
    id: 'wb_explore_payoff',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: 'oldWorld', ownerId: humanId),
          Province(id: p2, regionId: 'oldWorld', ownerId: humanId),
        ],
        units: [
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            locationProvinceId: p1,
            tileKey: targetTiles.first,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {p1: targetTiles, p2: otherTiles},
      },
      playerVisibilityByTile: {
        humanId: {
          for (final t in targetTiles) t: 'fullyVisible',
          if (targetTiles.length > 1) targetTiles.last: 'unknown',
        },
      },
    ),
    players: const [
      Player(id: humanId, displayName: 'Human', isHuman: true),
    ],
    minorNations: const [],
    tribes: const [],
  );
  final region = RegionMapViewData(
    regionId: 'oldWorld',
    width: targetTiles.length.clamp(1, 3),
    height: 1,
    cellSize: 16,
    cells: [
      for (var i = 0; i < targetTiles.length; i++)
        CellViewData(
          x: i,
          y: 0,
          regionCellId: 'p1',
          isSea: false,
          terrainType: TerrainType.plains,
          resourceId: 'grain',
          ownerFactionId: humanId,
          provinceDisplayName: 'Test Province',
          visibility: i == 0
              ? TileVisibility.fogged
              : TileVisibility.unrevealed,
        ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {humanId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {p1: humanId},
  );
  final playerView = buildPlayerView(
    game,
    const MapTopology(
      nodes: [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'p2',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    ),
    humanId,
  );
  return SizedBox(
    width: 360,
    height: 640,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: p1,
      selectedTileKey: targetTiles.first,
      humanPlayerId: humanId,
      playerView: playerView,
      civilianInlineActions: provinceOverlayInlineActions(
        explore: (
          showIcon: true,
          enabled: true,
          hasMatchingUnits: true,
        ),
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: () {},
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: null,
        onBuildRoadTap: null,
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}
